#!/bin/bash

echo "================================================="
echo "🔥 ЧЕК-ЛИСТ ЛАБОРАТОРНОЙ РАБОТЫ 6 🔥"
echo "REST API (FastAPI) и контейнеризация (Docker)"
echo "================================================="
echo ""

SCORE=0
TOTAL=8

# Проверка 1: API скрипт
if [ -f "src/api.py" ]; then
    echo "✅ src/api.py существует"
    SCORE=$((SCORE+1))
else
    echo "❌ src/api.py не найден"
fi

# Проверка 2: Dockerfile
if [ -f "Dockerfile" ]; then
    echo "✅ Dockerfile существует"
    SCORE=$((SCORE+1))
else
    echo "❌ Dockerfile не найден"
fi

# Проверка 3: README для API
if [ -f "API_README.md" ]; then
    echo "✅ API_README.md существует"
    SCORE=$((SCORE+1))
else
    echo "❌ API_README.md не найден"
fi

# Проверка 4: Модель существует
if [ -f "models/model.joblib" ]; then
    echo "✅ Модель существует"
    SCORE=$((SCORE+1))
else
    echo "❌ Модель не найдена"
fi

# Проверка 5: Docker образ
if command -v docker &> /dev/null; then
    if docker images | grep -q "flight-delay-api"; then
        echo "✅ Docker образ создан"
        SCORE=$((SCORE+1))
    else
        echo "❌ Docker образ не найден"
    fi
else
    echo "⚠️ Docker не установлен"
fi

# Проверка 6: Git коммит
if git log --oneline | grep -q "lab6"; then
    echo "✅ Коммит лабораторной 6 найден"
    SCORE=$((SCORE+1))
else
    echo "❌ Коммит не найден"
fi

# Проверка 7: Чистота директории
if [ -z "$(git status --porcelain)" ]; then
    echo "✅ Рабочая директория чиста"
    SCORE=$((SCORE+1))
else
    echo "❌ Есть незакоммиченные изменения"
    git status -s
fi

# Проверка 8: requirements.txt обновлен
if grep -q "fastapi" requirements.txt; then
    echo "✅ FastAPI в requirements.txt"
    SCORE=$((SCORE+1))
else
    echo "❌ FastAPI не найден в requirements.txt"
fi

echo ""
echo "================================================="
echo "ИТОГ: $SCORE/$TOTAL"
if [ $SCORE -eq $TOTAL ]; then
    echo "🔥 ЛАБОРАТОРНАЯ РАБОТА 6 ВЫПОЛНЕНА! 🔥"
else
    echo "⚠️ Выполнено $SCORE из $TOTAL"
fi
echo "================================================="
