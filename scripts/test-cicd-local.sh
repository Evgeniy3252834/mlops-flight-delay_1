#!/bin/bash

# Скрипт для локального тестирования CI/CD пайплайна

echo "🧪 Локальное тестирование CI/CD пайплайна"
echo "========================================="

# Шаг 1: Тесты
echo ""
echo "📋 Шаг 1: Запуск тестов..."
pytest tests/ -v

if [ $? -ne 0 ]; then
    echo "❌ Тесты не пройдены!"
    exit 1
fi
echo "✅ Тесты пройдены"

# Шаг 2: Линтинг
echo ""
echo "📋 Шаг 2: Проверка линтера..."
flake8 src/ tests/

if [ $? -ne 0 ]; then
    echo "❌ Линтер не пройден!"
    exit 1
fi
echo "✅ Линтер пройден"

# Шаг 3: Сборка Docker образа
echo ""
echo "📋 Шаг 3: Сборка Docker образа..."
docker build -t flight-delay-api:test .

if [ $? -ne 0 ]; then
    echo "❌ Сборка образа не удалась!"
    exit 1
fi
echo "✅ Docker образ собран"

# Шаг 4: Проверка образа
echo ""
echo "📋 Шаг 4: Проверка Docker образа..."
docker run --rm flight-delay-api:test python -c "import src.api; print('✅ API модуль загружен')"

if [ $? -ne 0 ]; then
    echo "❌ Проверка образа не удалась!"
    exit 1
fi
echo "✅ Docker образ прошел проверку"

# Шаг 5: Очистка
echo ""
echo "📋 Шаг 5: Очистка..."
docker rmi flight-delay-api:test

echo ""
echo "========================================="
echo "🎉 Локальное тестирование пройдено успешно!"
echo "========================================="
