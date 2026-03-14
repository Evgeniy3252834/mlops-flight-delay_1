#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Простой планировщик для периодического запуска проверки дрейфа
"""

import logging
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    handlers=[logging.FileHandler("logs/scheduler.log"), logging.StreamHandler()],
)
logger = logging.getLogger(__name__)


def run_drift_check():
    """Запуск проверки дрейфа"""
    logger.info("=" * 50)
    logger.info("🚀 Запуск проверки дрейфа")

    try:
        result = subprocess.run(
            [sys.executable, "src/drift_check.py"], capture_output=True, text=True
        )

        if result.returncode == 0:
            logger.info("✅ Проверка завершена, дрейф не обнаружен")
        elif result.returncode == 1:
            logger.info("🔄 Проверка завершена, обнаружен дрейф - запущено переобучение")
        else:
            logger.error(f"❌ Ошибка при проверке: {result.stderr}")

        # Логируем вывод
        if result.stdout:
            logger.debug(f"STDOUT: {result.stdout[-500:]}")

    except Exception as e:
        logger.error(f"❌ Исключение: {e}")


def main():
    """Основной цикл"""
    logger.info("=" * 60)
    logger.info("🚀 ЗАПУСК ПЛАНИРОВЩИКА ДРЕЙФА")
    logger.info("=" * 60)

    # Создаем директорию для логов
    Path("logs").mkdir(exist_ok=True)

    interval = 60  # Проверка каждые 60 секунд (для теста)

    try:
        while True:
            logger.info(f"⏳ Следующая проверка через {interval} сек")
            time.sleep(interval)
            run_drift_check()

    except KeyboardInterrupt:
        logger.info("👋 Планировщик остановлен")


if __name__ == "__main__":
    main()
