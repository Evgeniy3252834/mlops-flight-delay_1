#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Скрипт для обнаружения дрейфа данных и автоматического запуска переобучения
"""

import json
import logging
import os
import subprocess
import sys
from datetime import datetime, timedelta
from pathlib import Path

import joblib
import numpy as np
import pandas as pd
from evidently import ColumnMapping
from evidently.metrics import (ClassificationQualityMetric, ColumnDriftMetric,
                               DataDriftTable, DatasetDriftMetric,
                               RegressionQualityMetric)
from evidently.report import Report
from sklearn.metrics import accuracy_score, roc_auc_score

# Настройка логирования
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    handlers=[logging.FileHandler("reports/drift_check.log"), logging.StreamHandler()],
)
logger = logging.getLogger(__name__)

# Конфигурация
THRESHOLDS = {
    "data_drift": 0.1,  # Порог дрейфа данных (10% признаков изменилось)
    "performance_drift": 0.05,  # Порог падения метрики (5%)
    "psi_threshold": 0.2,  # Порог PSI для стабильности популяции
}

PATHS = {
    "reference_data": "data/processed/processed.csv",
    "current_data": "data/processed/current_data.csv",
    "model": "models/model.joblib",
    "model_features": "models/features.txt",
    "drift_report": "reports/drift_report.html",
    "drift_report_json": "reports/drift_report.json",
    "retrain_trigger": "reports/retrain_trigger.txt",
}


def load_data():
    """Загрузка эталонных и текущих данных"""
    logger.info("📥 Загрузка данных...")

    # Эталонные данные (исторические)
    if not os.path.exists(PATHS["reference_data"]):
        logger.error(f"❌ Эталонные данные не найдены: {PATHS['reference_data']}")
        return None, None

    reference_df = pd.read_csv(PATHS["reference_data"])
    logger.info(f"✅ Эталонные данные: {len(reference_df)} строк")

    # Текущие данные (для проверки дрейфа)
    if os.path.exists(PATHS["current_data"]):
        current_df = pd.read_csv(PATHS["current_data"])
        logger.info(f"✅ Текущие данные: {len(current_df)} строк")
    else:
        logger.warning("⚠️ Текущие данные не найдены, создаем синтетические...")
        current_df = create_synthetic_drift(reference_df)

    return reference_df, current_df


def create_synthetic_drift(reference_df, drift_intensity=0.3):
    """Создание синтетических данных с дрейфом для тестирования"""
    logger.info(
        f"🔄 Создание синтетических данных с дрейфом (интенсивность={drift_intensity})..."
    )

    # Копируем эталонные данные
    current_df = reference_df.copy()

    # Добавляем дрейф в некоторые признаки
    np.random.seed(42)

    # Дрейф в задержках (увеличиваем на 30%)
    if "dep_delay" in current_df.columns:
        current_df["dep_delay"] = current_df["dep_delay"] * (1 + drift_intensity)

    if "arr_delay" in current_df.columns:
        current_df["arr_delay"] = current_df["arr_delay"] * (1 + drift_intensity)

    # Дрейф в расстояниях
    if "distance" in current_df.columns:
        current_df["distance"] = current_df["distance"] * (
            1 + np.random.uniform(-0.1, 0.1)
        )

    # Дрейф в авиакомпаниях (изменяем распределение)
    if "carrier" in current_df.columns:
        # Увеличиваем долю UA и DL
        carriers = current_df["carrier"].values
        for i, c in enumerate(carriers):
            if c in ["AA", "WN", "B6"] and np.random.random() < drift_intensity:
                carriers[i] = np.random.choice(["UA", "DL"])
        current_df["carrier"] = carriers

    logger.info(f"✅ Синтетические данные созданы: {len(current_df)} строк")
    return current_df


def calculate_psi(expected, actual, bins=10):
    """Расчет Population Stability Index (PSI)"""
    # Разбиваем на бины
    expected_counts, bin_edges = np.histogram(expected, bins=bins)
    actual_counts, _ = np.histogram(actual, bins=bin_edges)

    # Нормализуем
    expected_pct = expected_counts / len(expected)
    actual_pct = actual_counts / len(actual)

    # Добавляем маленькое значение чтобы избежать деления на ноль
    expected_pct = np.clip(expected_pct, 0.001, 1)
    actual_pct = np.clip(actual_pct, 0.001, 1)

    # Расчет PSI
    psi = np.sum((actual_pct - expected_pct) * np.log(actual_pct / expected_pct))

    return psi


def check_drift_with_evidently(reference_df, current_df):
    """Проверка дрейфа с помощью evidently"""
    logger.info("🔍 Запуск анализа дрейфа с evidently...")

    # Определяем колонки
    numerical_features = reference_df.select_dtypes(
        include=[np.number]
    ).columns.tolist()
    categorical_features = reference_df.select_dtypes(
        include=["object"]
    ).columns.tolist()

    # Убираем целевую переменную из признаков
    if "delay_flag" in numerical_features:
        numerical_features.remove("delay_flag")

    column_mapping = ColumnMapping(
        target="delay_flag" if "delay_flag" in reference_df.columns else None,
        prediction=None,
        numerical_features=numerical_features,
        categorical_features=categorical_features,
    )

    # Создаем отчет о дрейфе
    drift_report = Report(
        metrics=[
            DataDriftTable(),
            DatasetDriftMetric(),
        ]
    )

    drift_report.run(
        reference_data=reference_df,
        current_data=current_df,
        column_mapping=column_mapping,
    )

    # Сохраняем отчет
    drift_report.save_html(PATHS["drift_report"])
    logger.info(f"✅ Отчет сохранен: {PATHS['drift_report']}")

    # Получаем результаты
    results = drift_report.as_dict()

    # Извлекаем метрики дрейфа
    drift_metrics = {
        "number_of_columns": results["metrics"][0]["result"]["number_of_columns"],
        "number_of_drifted_columns": results["metrics"][0]["result"][
            "number_of_drifted_columns"
        ],
        "share_of_drifted_columns": results["metrics"][0]["result"][
            "share_of_drifted_columns"
        ],
        "dataset_drift": results["metrics"][1]["result"]["drift_detected"],
    }

    logger.info(f"📊 Результаты дрейфа:")
    logger.info(
        f"   - Дрейфующих признаков: {drift_metrics['number_of_drifted_columns']}/{drift_metrics['number_of_columns']}"
    )
    logger.info(f"   - Доля дрейфа: {drift_metrics['share_of_drifted_columns']:.2%}")
    logger.info(f"   - Дрейф датасета: {drift_metrics['dataset_drift']}")

    return drift_metrics


def check_performance_drift(model, reference_df, current_df):
    """Проверка дрейфа производительности модели"""
    logger.info("📈 Проверка дрейфа производительности...")

    # Подготовка признаков
    feature_cols = [col for col in reference_df.columns if col != "delay_flag"]

    # Эталонные данные
    X_ref = reference_df[feature_cols]
    y_ref = reference_df["delay_flag"]

    # Текущие данные
    X_cur = current_df[feature_cols]
    y_cur = current_df["delay_flag"]

    # Предсказания на эталонных данных
    y_ref_pred = model.predict(X_ref)
    y_ref_proba = model.predict_proba(X_ref)[:, 1]

    # Предсказания на текущих данных
    y_cur_pred = model.predict(X_cur)
    y_cur_proba = model.predict_proba(X_cur)[:, 1]

    # Метрики на эталонных данных
    ref_accuracy = accuracy_score(y_ref, y_ref_pred)
    ref_roc_auc = roc_auc_score(y_ref, y_ref_proba)

    # Метрики на текущих данных
    cur_accuracy = accuracy_score(y_cur, y_cur_pred)
    cur_roc_auc = roc_auc_score(y_cur, y_cur_proba)

    # Расчет дрейфа производительности
    performance_drift = {
        "accuracy_drift": ref_accuracy - cur_accuracy,
        "roc_auc_drift": ref_roc_auc - cur_roc_auc,
        "ref_accuracy": ref_accuracy,
        "cur_accuracy": cur_accuracy,
        "ref_roc_auc": ref_roc_auc,
        "cur_roc_auc": cur_roc_auc,
        "drift_detected": (ref_accuracy - cur_accuracy)
        > THRESHOLDS["performance_drift"]
        or (ref_roc_auc - cur_roc_auc) > THRESHOLDS["performance_drift"],
    }

    logger.info(f"📊 Результаты производительности:")
    logger.info(f"   - Accuracy (reference): {ref_accuracy:.4f}")
    logger.info(f"   - Accuracy (current): {cur_accuracy:.4f}")
    logger.info(f"   - ROC-AUC (reference): {ref_roc_auc:.4f}")
    logger.info(f"   - ROC-AUC (current): {cur_roc_auc:.4f}")
    logger.info(f"   - Дрейф производительности: {performance_drift['drift_detected']}")

    return performance_drift


def trigger_retraining(drift_metrics, performance_metrics):
    """Запуск переобучения при обнаружении дрейфа"""

    reasons = []

    # Проверяем дрейф данных
    if drift_metrics["dataset_drift"]:
        reasons.append(
            f"Дрейф данных: {drift_metrics['share_of_drifted_columns']:.2%} признаков изменилось"
        )

    if drift_metrics["share_of_drifted_columns"] > THRESHOLDS["data_drift"]:
        reasons.append(
            f"Превышен порог дрейфа признаков: {drift_metrics['share_of_drifted_columns']:.2%} > {THRESHOLDS['data_drift']:.2%}"
        )

    # Проверяем дрейф производительности
    if performance_metrics["drift_detected"]:
        reasons.append(
            f"Дрейф производительности: accuracy упала на {performance_metrics['accuracy_drift']:.4f}"
        )

    if reasons:
        logger.warning("⚠️ ДРЕЙФ ОБНАРУЖЕН! Причины:")
        for reason in reasons:
            logger.warning(f"   • {reason}")

        # Запускаем переобучение
        logger.info("🔄 Запуск переобучения модели...")

        # Сохраняем триггер для переобучения
        trigger_info = {
            "timestamp": datetime.now().isoformat(),
            "reasons": reasons,
            "drift_metrics": drift_metrics,
            "performance_metrics": performance_metrics,
        }

        with open(PATHS["retrain_trigger"], "w") as f:
            json.dump(trigger_info, f, indent=2)

        # Запускаем скрипт обучения
        try:
            result = subprocess.run(
                [sys.executable, "src/train.py", "--model_type", "random_forest"],
                capture_output=True,
                text=True,
            )

            if result.returncode == 0:
                logger.info("✅ Переобучение успешно завершено")
                logger.info(f"   Вывод: {result.stdout[-200:]}")
            else:
                logger.error(f"❌ Ошибка переобучения: {result.stderr}")

        except Exception as e:
            logger.error(f"❌ Исключение при переобучении: {e}")

        return True
    else:
        logger.info("✅ Дрейф не обнаружен, переобучение не требуется")
        return False


def main():
    """Основная функция"""
    logger.info("=" * 60)
    logger.info("🚀 ЗАПУСК ДЕТЕКЦИИ ДРЕЙФА")
    logger.info("=" * 60)

    # Загружаем данные
    reference_df, current_df = load_data()
    if reference_df is None or current_df is None:
        logger.error("❌ Не удалось загрузить данные")
        sys.exit(1)

    # Загружаем модель
    if not os.path.exists(PATHS["model"]):
        logger.error(f"❌ Модель не найдена: {PATHS['model']}")
        sys.exit(1)

    model = joblib.load(PATHS["model"])
    logger.info("✅ Модель загружена")

    # Проверяем дрейф данных
    drift_metrics = check_drift_with_evidently(reference_df, current_df)

    # Проверяем дрейф производительности
    performance_metrics = check_performance_drift(model, reference_df, current_df)

    # Сохраняем результаты
    results = {
        "timestamp": datetime.now().isoformat(),
        "drift_metrics": drift_metrics,
        "performance_metrics": performance_metrics,
        "thresholds": THRESHOLDS,
        "retraining_triggered": False,
    }

    # Запускаем переобучение при необходимости
    retraining_triggered = trigger_retraining(drift_metrics, performance_metrics)
    results["retraining_triggered"] = retraining_triggered

    # Сохраняем результаты
    with open(PATHS["drift_report_json"], "w") as f:
        json.dump(results, f, indent=2)

    logger.info("=" * 60)
    logger.info(
        f"🏁 ДЕТЕКЦИЯ ДРЕЙФА ЗАВЕРШЕНА. Переобучение: {'✅' if retraining_triggered else '❌'}"
    )
    logger.info("=" * 60)

    return 0 if not retraining_triggered else 1


if __name__ == "__main__":
    sys.exit(main())
