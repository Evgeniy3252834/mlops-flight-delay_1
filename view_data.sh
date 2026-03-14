#!/bin/bash
echo "========================================="
echo "ДАННЫЕ ЭКСПЕРИМЕНТА flight_delay_prediction"
echo "========================================="

# Получаем успешные запуски
runs=$(sqlite3 mlflow.db "SELECT run_uuid FROM runs WHERE experiment_id=1 AND status='FINISHED';")

for run in $runs; do
    echo -e "\n📊 Run ID: $run"
    echo "-------------------"
    
    # Параметры
    sqlite3 mlflow.db "SELECT key, value FROM params WHERE run_uuid='$run';" | while IFS='|' read key value; do
        echo "  ⚙️ $key = $value"
    done
    
    # Метрики
    sqlite3 mlflow.db "SELECT key, value FROM metrics WHERE run_uuid='$run';" | while IFS='|' read key value; do
        echo "  📈 $key = $value"
    done
done
