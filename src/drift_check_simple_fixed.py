#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Упрощенная детекция дрейфа - исправленная версия
"""

import json
import logging
import os
import subprocess
import sys
from datetime import datetime

import joblib
import pandas as pd
from sklearn.metrics import accuracy_score

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

THRESHOLDS = {"performance_drift": 0.05}


def check_drift():
    logger.info("=" * 60)
    logger.info("🚀 ПРОВЕРКА ДРЕЙФА")
    logger.info("=" * 60)

    # Загружаем данные
    reference_df = pd.read_csv("data/processed/processed.csv")

    current_path = "data/processed/current_data.csv"
    if os.path.exists(current_path):
        current_df = pd.read_csv(current_path)
    else:
        logger.warning("Текущие данные не найдены, использую reference")
        current_df = reference_df.copy()

    # Загружаем модель
    model = joblib.load("models/model.joblib")

    # Получаем признаки, которые ожидает модель
    expected_features = model.feature_names_in_.tolist()
    logger.info(f"Модель ожидает {len(expected_features)} признаков")

    # Проверяем наличие всех признаков
    missing_features = [f for f in expected_features if f not in reference_df.columns]
    if missing_features:
        logger.warning(f"Отсутствуют признаки: {missing_features}")

    # Используем только те признаки, которые есть
    common_features = [f for f in expected_features if f in reference_df.columns]
    logger.info(f"Используем {len(common_features)} общих признаков")

    # Подготовка данных
    X_ref = reference_df[common_features]
    y_ref = reference_df["delay_flag"]
    X_cur = current_df[common_features]
    y_cur = current_df["delay_flag"]

    # Предсказания
    ref_pred = model.predict(X_ref)
    cur_pred = model.predict(X_cur)

    # Метрики
    ref_acc = accuracy_score(y_ref, ref_pred)
    cur_acc = accuracy_score(y_cur, cur_pred)

    logger.info(f"\n📈 Производительность:")
    logger.info(f"   Reference accuracy: {ref_acc:.4f}")
    logger.info(f"   Current accuracy: {cur_acc:.4f}")
    logger.info(f"   Дрейф: {ref_acc - cur_acc:.4f}")

    # Решение о переобучении
    drift_detected = (ref_acc - cur_acc) > THRESHOLDS["performance_drift"]

    if drift_detected:
        logger.warning("⚠️ ДРЕЙФ ОБНАРУЖЕН! Запуск переобучения...")

        try:
            result = subprocess.run(
                [sys.executable, "src/train.py", "--model_type", "random_forest"],
                capture_output=True,
                text=True,
                timeout=60,
            )

            if result.returncode == 0:
                logger.info("✅ Переобучение успешно")
                logger.info(f"   Вывод: {result.stdout[-200:]}")
            else:
                logger.error(f"❌ Ошибка: {result.stderr}")
        except Exception as e:
            logger.error(f"❌ Исключение при переобучении: {e}")
    else:
        logger.info("✅ Дрейф не обнаружен")

    # Сохраняем отчет
    report = {
        "timestamp": datetime.now().isoformat(),
        "reference_accuracy": float(ref_acc),
        "current_accuracy": float(cur_acc),
        "drift_detected": drift_detected,
        "features_used": len(common_features),
    }

    with open("reports/drift_report_simple.json", "w") as f:
        json.dump(report, f, indent=2)

    logger.info("✅ Отчет сохранен в reports/drift_report_simple.json")
    return drift_detected


if __name__ == "__main__":
    check_drift()
