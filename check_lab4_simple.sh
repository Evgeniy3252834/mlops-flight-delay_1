#!/bin/bash
echo "========================================="
echo "🔥 ПРОВЕРКА ЛАБОРАТОРНОЙ РАБОТЫ 4 🔥"
echo "========================================="

SCORE=0
TOTAL=6

# Проверка 1: Скрипт обучения
if [ -f "src/train.py" ]; then
    echo "✅ src/train.py существует"
    SCORE=$((SCORE+1))
else
    echo "❌ src/train.py не найден"
fi

# Проверка 2: Модель
if [ -f "models/model.joblib" ]; then
    echo "✅ models/model.joblib существует"
    SCORE=$((SCORE+1))
else
    echo "❌ models/model.joblib не найден"
fi

# Проверка 3: Метрики
if [ -f "reports/metrics.json" ]; then
    echo "✅ reports/metrics.json существует"
    SCORE=$((SCORE+1))
    echo "   Метрики:"
    cat reports/metrics.json | grep -E "accuracy|roc_auc" | head -3
else
    echo "❌ reports/metrics.json не найден"
fi

# Проверка 4: Признаки
if [ -f "models/features.txt" ]; then
    echo "✅ models/features.txt существует"
    SCORE=$((SCORE+1))
else
    echo "❌ models/features.txt не найден"
fi

# Проверка 5: MLflow база
if [ -f "mlflow.db" ]; then
    echo "✅ mlflow.db существует"
    SCORE=$((SCORE+1))
    # Проверка запусков
    RUNS=$(sqlite3 mlflow.db "SELECT COUNT(*) FROM runs WHERE status='FINISHED';" 2>/dev/null)
    echo "   Успешных запусков: $RUNS"
else
    echo "❌ mlflow.db не найден"
fi

# Проверка 6: Git коммит
if git log --oneline | grep -q "lab4: FINAL VERSION"; then
    echo "✅ Коммит лабораторной 4 найден"
    SCORE=$((SCORE+1))
else
    echo "❌ Коммит не найден"
fi

echo "========================================="
echo "ИТОГ: $SCORE/$TOTAL"
if [ $SCORE -eq $TOTAL ]; then
    echo "🔥 ЛАБОРАТОРНАЯ РАБОТА 4 ВЫПОЛНЕНА НА 100%! 🔥"
else
    echo "⚠️ Выполнено $SCORE из $TOTAL"
fi
echo "========================================="
