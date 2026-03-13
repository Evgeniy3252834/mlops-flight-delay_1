#!/bin/bash

echo "================================================="
echo "🔥 ЧЕК-ЛИСТ ЛАБОРАТОРНОЙ РАБОТЫ 7 🔥"
echo "Тестирование и CI (GitHub Actions)"
echo "================================================="
echo ""

SCORE=0
TOTAL=8

# Проверка 1: Директория tests
if [ -d "tests" ]; then
    echo "✅ Директория tests существует"
    SCORE=$((SCORE+1))
else
    echo "❌ Директория tests не найдена"
fi

# Проверка 2: conftest.py
if [ -f "tests/conftest.py" ]; then
    echo "✅ conftest.py существует"
    SCORE=$((SCORE+1))
else
    echo "❌ conftest.py не найден"
fi

# Проверка 3: test_api.py
if [ -f "tests/test_api.py" ]; then
    echo "✅ test_api.py существует"
    SCORE=$((SCORE+1))
else
    echo "❌ test_api.py не найден"
fi

# Проверка 4: test_preprocess.py
if [ -f "tests/test_preprocess.py" ]; then
    echo "✅ test_preprocess.py существует"
    SCORE=$((SCORE+1))
else
    echo "❌ test_preprocess.py не найден"
fi

# Проверка 5: GitHub Actions workflow
if [ -f ".github/workflows/ci.yml" ]; then
    echo "✅ GitHub Actions workflow существует"
    SCORE=$((SCORE+1))
else
    echo "❌ GitHub Actions workflow не найден"
fi

# Проверка 6: pytest.ini
if [ -f "pytest.ini" ]; then
    echo "✅ pytest.ini существует"
    SCORE=$((SCORE+1))
else
    echo "❌ pytest.ini не найден"
fi

# Проверка 7: Тесты проходят
if command -v pytest &> /dev/null; then
    pytest tests/ -q --tb=no > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "✅ Тесты проходят успешно"
        SCORE=$((SCORE+1))
    else
        echo "❌ Тесты не проходят"
    fi
else
    echo "⚠️ pytest не установлен"
fi

# Проверка 8: Git коммит
if git log --oneline | grep -q "lab7"; then
    echo "✅ Коммит лабораторной 7 найден"
    SCORE=$((SCORE+1))
else
    echo "❌ Коммит не найден"
fi

echo ""
echo "================================================="
echo "ИТОГ: $SCORE/$TOTAL"
if [ $SCORE -eq $TOTAL ]; then
    echo "🔥 ЛАБОРАТОРНАЯ РАБОТА 7 ВЫПОЛНЕНА! 🔥"
else
    echo "⚠️ Выполнено $SCORE из $TOTAL"
fi
echo "================================================="
