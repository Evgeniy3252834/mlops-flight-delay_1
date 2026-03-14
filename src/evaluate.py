#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Скрипт для оценки модели
"""

import argparse
# import numpy as np  # закомментировали, не используется
import json
import logging
from pathlib import Path

import joblib
import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns
from sklearn.metrics import (accuracy_score, confusion_matrix, f1_score,
                             precision_score, recall_score, roc_auc_score)
from sklearn.model_selection import train_test_split

# from datetime import datetime  # закомментировали, не используется
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

Path("reports/figures").mkdir(parents=True, exist_ok=True)


def load_model_and_data(model_path="models/model.joblib"):
    """Загрузка модели и данных"""

    logger.info(f"Загрузка модели из {model_path}")
    model = joblib.load(model_path)

    logger.info("Загрузка данных...")
    df = pd.read_csv("data/processed/processed.csv")

    # Только те колонки, что были при обучении
    exclude_cols = [
        "delay_flag",
        "flight_date",
        "dep_time",
        "arr_time",
        "dep_delay",
        "arr_delay",
        "flight_id",
    ]

    feature_cols = [
        col
        for col in df.columns
        if col not in exclude_cols and df[col].dtype in ["int64", "float64", "bool"]
    ]

    X = df[feature_cols]
    y = df["delay_flag"]

    _, X_test, _, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )

    logger.info(f"Тестовая выборка: {len(X_test)} строк")
    logger.info(f"Признаки: {feature_cols}")

    return model, X_test, y_test, feature_cols


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--model_path", type=str, default="models/model.joblib")
    parser.add_argument("--register", action="store_true")
    parser.add_argument("--stage", type=str, default="Staging")
    args = parser.parse_args()

    logger.info("=" * 60)
    logger.info("НАЧАЛО ОЦЕНКИ МОДЕЛИ")
    logger.info("=" * 60)

    # Загрузка
    model, X_test, y_test, feature_names = load_model_and_data(args.model_path)

    # Предсказания
    y_pred = model.predict(X_test)
    y_pred_proba = model.predict_proba(X_test)[:, 1]

    # Метрики
    metrics = {
        "accuracy": accuracy_score(y_test, y_pred),
        "roc_auc": roc_auc_score(y_test, y_pred_proba),
        "precision": precision_score(y_test, y_pred),
        "recall": recall_score(y_test, y_pred),
        "f1_score": f1_score(y_test, y_pred),
    }

    logger.info("\n📊 Метрики:")
    for k, v in metrics.items():
        logger.info(f"  {k}: {v:.4f}")

    # Сохраняем метрики
    with open("reports/metrics_detailed.json", "w") as f:
        json.dump(metrics, f, indent=2)

    # Матрица ошибок
    plt.figure(figsize=(8, 6))
    cm = confusion_matrix(y_test, y_pred)
    sns.heatmap(cm, annot=True, fmt="d", cmap="Blues")
    plt.title("Confusion Matrix")
    plt.savefig("reports/figures/confusion_matrix.png")
    plt.close()

    logger.info("✅ Отчеты сохранены в reports/")
    logger.info("=" * 60)


if __name__ == "__main__":
    main()
