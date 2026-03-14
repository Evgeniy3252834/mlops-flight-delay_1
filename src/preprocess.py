#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Скрипт для предобработки данных о задержках рейсов
"""

import logging
import os
import sys
from pathlib import Path

import numpy as np
import pandas as pd

# Настройка логирования
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


def create_features(df):
    """
    Создание признаков для модели
    """
    logger.info("Создание новых признаков...")

    # Копируем DataFrame
    df = df.copy()

    # 1. Преобразование даты
    logger.info("  - Преобразование даты")
    df["flight_date"] = pd.to_datetime(df["flight_date"])
    df["day_of_week"] = df["flight_date"].dt.dayofweek
    df["is_weekend"] = (df["day_of_week"] >= 5).astype(int)
    df["month"] = df["flight_date"].dt.month
    df["day_of_month"] = df["flight_date"].dt.day

    # 2. Обработка времени вылета
    logger.info("  - Обработка времени вылета")
    df["dep_hour"] = df["dep_time"] // 100
    df["dep_minute"] = df["dep_time"] % 100

    # 3. Бакетизация часа вылета
    logger.info("  - Создание временных категорий")
    conditions = [
        (df["dep_hour"] < 6),
        (df["dep_hour"] < 12),
        (df["dep_hour"] < 18),
        (df["dep_hour"] <= 23),
    ]
    choices = ["night", "morning", "afternoon", "evening"]
    df["dep_time_bucket"] = np.select(conditions, choices, default="unknown")

    # 4. Признаки на основе расстояния
    logger.info("  - Признаки расстояния")
    df["distance_km"] = df["distance"] * 1.60934
    df["distance_category"] = pd.cut(
        df["distance"],
        bins=[0, 500, 1000, 2000, 5000],
        labels=["short", "medium", "long", "very_long"],
    )

    # 5. Целевая переменная
    logger.info("  - Создание целевой переменной")
    df["delay_flag"] = (df["dep_delay"] > 15).astype(int)

    # 6. Дополнительные признаки
    logger.info("  - Дополнительные признаки")
    df["delay_ratio"] = df["arr_delay"] / (df["dep_delay"] + 1)
    df["significant_delay"] = (df["dep_delay"] > 30).astype(int)

    # 7. Очистка от пропущенных значений
    logger.info("  - Очистка от пропущенных значений")
    df = df.dropna()

    # 8. Удаление дубликатов
    logger.info("  - Удаление дубликатов")
    df = df.drop_duplicates()

    logger.info(f"Создано признаков: {len(df.columns)}")
    return df


def main():
    """Основная функция"""
    logger.info("=" * 60)
    logger.info("НАЧАЛО ПРЕДОБРАБОТКИ ДАННЫХ")
    logger.info("=" * 60)

    # Создание директории
    Path("data/processed").mkdir(parents=True, exist_ok=True)

    # Пути к файлам
    input_path = "data/raw/flights_sample.csv"
    output_path = "data/processed/processed.csv"

    # Проверка файла
    if not os.path.exists(input_path):
        logger.error(f"Файл {input_path} не найден!")
        sys.exit(1)

    # Чтение данных
    logger.info(f"Чтение данных из {input_path}")
    df = pd.read_csv(input_path)
    logger.info(f"Загружено {len(df)} строк")
    logger.info(f"Колонки: {list(df.columns)}")

    # Статистика до обработки
    logger.info("\nСтатистика до обработки:")
    logger.info(f"Пропущенные значения: {df.isnull().sum().sum()}")
    logger.info(f"Дубликаты: {df.duplicated().sum()}")

    if "dep_delay" in df.columns:
        logger.info(f"Средняя задержка: {df['dep_delay'].mean():.2f} мин")
        delay_pct = (df["dep_delay"] > 15).mean() * 100
        logger.info(f"Доля задержанных: {delay_pct:.1f}%")

    # Создание признаков
    logger.info("\n" + "=" * 40)
    df_processed = create_features(df)

    # Статистика после обработки
    logger.info("\n" + "=" * 40)
    logger.info("Статистика после обработки:")
    logger.info(f"Всего строк: {len(df_processed)}")
    logger.info(f"Всего колонок: {len(df_processed.columns)}")
    logger.info(f"Пропущенные значения: {df_processed.isnull().sum().sum()}")
    delay_rate = df_processed["delay_flag"].mean() * 100
    logger.info(f"Доля задержанных: {delay_rate:.1f}%")

    # Сохранение
    logger.info(f"\nСохранение в {output_path}")
    df_processed.to_csv(output_path, index=False)

    # Метаданные
    features_info = {
        "original_features": list(df.columns),
        "engineered_features": list(df_processed.columns),
        "total_features": len(df_processed.columns),
        "total_samples": len(df_processed),
        "delay_rate": float(df_processed["delay_flag"].mean()),
    }

    import json

    with open("data/processed/features_info.json", "w") as f:
        json.dump(features_info, f, indent=2)

    logger.info("\n" + "=" * 60)
    logger.info("ПРЕДОБРАБОТКА ЗАВЕРШЕНА УСПЕШНО")
    logger.info("=" * 60)

    # Первые строки
    logger.info("\nПервые 3 строки:")
    logger.info("\n" + str(df_processed.head(3).to_string()))


if __name__ == "__main__":
    main()
