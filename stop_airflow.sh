#!/bin/bash

echo "🛑 Остановка Airflow..."

docker-compose -f docker-compose-airflow.yml down

echo "✅ Airflow остановлен"
