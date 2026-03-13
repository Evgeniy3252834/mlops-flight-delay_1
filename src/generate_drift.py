#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Скрипт для генерации данных с дрейфом для тестирования
"""

import argparse
import logging
from pathlib import Path

import numpy as np
import pandas as pd

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def generate_drift_data(intensity=0.3, output_file="data/processed/current_data.csv"):
    """Генерация данных с дрейфом"""

    logger.info(f"🔄 Генерация данных с дрейфом (интенсивность={intensity})...")

    # Загружаем исходные данные
    input_file = "data/processed/processed.csv"
    if not Path(input_file).exists():
        logger.error(f"❌ Файл {input_file} не найден")
        return False

    df = pd.read_csv(input_file)
    logger.info(f"✅ Загружено {len(df)} строк")

    # Копируем для модификации
    drift_df = df.copy()

    np.random.seed(42)

    # 1. Дрейф в задержках (увеличиваем)
    if "dep_delay" in drift_df.columns:
        drift_df["dep_delay"] = drift_df["dep_delay"] * (
            1 + intensity * np.random.uniform(0.5, 1.5, len(drift_df))
        )
        logger.info("   • Дрейф в dep_delay")

    if "arr_delay" in drift_df.columns:
        drift_df["arr_delay"] = drift_df["arr_delay"] * (
            1 + intensity * np.random.uniform(0.5, 1.5, len(drift_df))
        )
        logger.info("   • Дрейф в arr_delay")

    # 2. Дрейф в расстояниях
    if "distance" in drift_df.columns:
        drift_df["distance"] = drift_df["distance"] * (
            1 + np.random.uniform(-0.1, 0.1, len(drift_df)) * intensity
        )
        logger.info("   • Дрейф в distance")

    # 3. Дрейф в часах вылета
    if "dep_hour" in drift_df.columns:
        # Сдвигаем часы (больше вечерних рейсов)
        mask = drift_df["dep_hour"] < 12
        drift_df.loc[mask, "dep_hour"] = drift_df.loc[
            mask, "dep_hour"
        ] + np.random.randint(1, 4, mask.sum())
        drift_df["dep_hour"] = drift_df["dep_hour"].clip(0, 23)
        logger.info("   • Дрейф в dep_hour")

    # 4. Дрейф в авиакомпаниях
    if "carrier" in drift_df.columns:
        # Увеличиваем долю UA и DL
        carriers = drift_df["carrier"].values
        for i in range(len(carriers)):
            if carriers[i] in ["AA", "WN", "B6"] and np.random.random() < intensity:
                carriers[i] = np.random.choice(["UA", "DL"])
        drift_df["carrier"] = carriers
        logger.info("   • Дрейф в carrier")

    # 5. Дрейф в целевой переменной
    if "delay_flag" in drift_df.columns:
        # Увеличиваем долю задержек
        current_rate = drift_df["delay_flag"].mean()
        target_rate = min(current_rate * (1 + intensity), 0.9)

        # Меняем некоторые 0 на 1
        zero_mask = drift_df["delay_flag"] == 0
        n_to_change = int(
            zero_mask.sum() * (target_rate - current_rate) / (1 - current_rate)
        )

        if n_to_change > 0:
            indices = (
                drift_df[zero_mask].sample(n=min(n_to_change, zero_mask.sum())).index
            )
            drift_df.loc[indices, "delay_flag"] = 1

        logger.info(
            f"   • Дрейф в delay_flag: {current_rate:.2%} -> {drift_df['delay_flag'].mean():.2%}"
        )

    # Сохраняем
    drift_df.to_csv(output_file, index=False)
    logger.info(f"✅ Данные с дрейфом сохранены: {output_file}")
    logger.info(f"   • Всего строк: {len(drift_df)}")
    logger.info(f"   • Интенсивность дрейфа: {intensity}")

    return True


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--intensity", type=float, default=0.3, help="Интенсивность дрейфа (0.0-1.0)"
    )
    parser.add_argument(
        "--output",
        type=str,
        default="data/processed/current_data.csv",
        help="Выходной файл",
    )
    args = parser.parse_args()

    generate_drift_data(args.intensity, args.output)


if __name__ == "__main__":
    main()
