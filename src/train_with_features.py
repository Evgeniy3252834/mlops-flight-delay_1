#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Обучение модели с использованием Feature Store
"""

import logging

import joblib
import pandas as pd
from feast import FeatureStore
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def main():
    logger.info("=" * 60)
    logger.info("🚀 ОБУЧЕНИЕ С FEATURE STORE")
    logger.info("=" * 60)

    # Загружаем Feature Store
    fs = FeatureStore(repo_path="feature_repo/my_feature_repo/feature_repo")
    logger.info("✅ Feature Store загружен")

    # Загружаем данные
    df = pd.read_csv("data/processed/processed.csv")
    logger.info(f"✅ Загружено {len(df)} строк")

    # Получаем признаки для каждого рейса
    logger.info("📦 Загрузка признаков из Feature Store...")

    features = []
    for _, row in df.iterrows():
        # Признаки по авиакомпании
        carrier_feat = fs.get_online_features(
            features=[
                "carrier_statistics:avg_dep_delay",
                "carrier_statistics:delay_rate",
            ],
            entity_rows=[{"carrier": row["carrier"]}],
        ).to_dict()

        features.append(
            {
                "carrier_avg_delay": carrier_feat["avg_dep_delay"][0],
                "carrier_delay_rate": carrier_feat["delay_rate"][0],
            }
        )

    X = pd.DataFrame(features)
    y = df["delay_flag"]

    logger.info(f"✅ Подготовлено {X.shape[1]} признаков")

    # Разделяем данные
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42
    )

    # Обучаем модель
    logger.info("\n🤖 Обучение модели...")
    model = RandomForestClassifier(n_estimators=100, max_depth=10, random_state=42)
    model.fit(X_train, y_train)

    # Оцениваем
    y_pred = model.predict(X_test)
    accuracy = accuracy_score(y_test, y_pred)

    logger.info(f"\n📊 Результаты: accuracy={accuracy:.4f}")

    # Сохраняем модель
    model_path = "models/model_with_features.joblib"
    joblib.dump(model, model_path)
    logger.info(f"✅ Модель сохранена: {model_path}")

    logger.info("\n" + "=" * 60)
    logger.info("✅ ОБУЧЕНИЕ ЗАВЕРШЕНО")
    logger.info("=" * 60)


if __name__ == "__main__":
    main()
