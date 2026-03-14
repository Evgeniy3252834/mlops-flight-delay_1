#!/bin/bash

echo "🚀 Запуск Airflow с Docker Compose..."

# Останавливаем старые контейнеры если есть
docker-compose -f docker-compose-airflow.yml down

# Запускаем контейнеры
docker-compose -f docker-compose-airflow.yml up -d

echo "✅ Airflow запущен!"
echo "📊 Web UI: http://localhost:8081"
echo "👤 Логин: admin"
echo "🔑 Пароль: admin"
echo ""
echo "Для просмотра логов: docker-compose -f docker-compose-airflow.yml logs -f"
echo "Для остановки: docker-compose -f docker-compose-airflow.yml down"
