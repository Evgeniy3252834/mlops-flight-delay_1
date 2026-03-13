#!/bin/bash

echo "================================================="
echo "🔥 ЧЕК-ЛИСТ ЛАБОРАТОРНОЙ РАБОТЫ 14 🔥"
echo "Итоговая интеграция, демонстрация и отчёт"
echo "================================================="
echo ""

SCORE=0
TOTAL=10

# Проверка 1: README_FINAL.md
if [ -f "README_FINAL.md" ]; then
    echo "✅ README_FINAL.md существует"
    SCORE=$((SCORE+1))
else
    echo "❌ README_FINAL.md не найден"
fi

# Проверка 2: docs/project_report.md
if [ -f "docs/project_report.md" ]; then
    echo "✅ project_report.md существует"
    SCORE=$((SCORE+1))
else
    echo "❌ project_report.md не найден"
fi

# Проверка 3: demo директория
if [ -d "demo" ] && [ -f "demo/README_demo.md" ]; then
    echo "✅ Инструкция для демо существует"
    SCORE=$((SCORE+1))
else
    echo "❌ Инструкция для демо не найдена"
fi

# Проверка 4: Все лабораторные выполнены
LAB_COUNT=$(ls -la lab* 2>/dev/null | wc -l)
if [ $LAB_COUNT -ge 10 ]; then
    echo "✅ Все лабораторные работы на месте"
    SCORE=$((SCORE+1))
else
    echo "⚠️ Некоторые лабораторные отсутствуют (но это норм)"
fi

# Проверка 5: Git коммит
if git log --oneline | grep -q "lab14"; then
    echo "✅ Коммит лабораторной 14 найден"
    SCORE=$((SCORE+1))
else
    echo "❌ Коммит не найден"
fi

# Проверка 6: Чистота рабочей директории
if [ -z "$(git status --porcelain)" ]; then
    echo "✅ Рабочая директория чиста"
    SCORE=$((SCORE+1))
else
    echo "❌ Есть незакоммиченные изменения"
    git status -s
fi

# Проверка 7: Наличие всех ключевых компонентов
if [ -d "src" ] && [ -d "data" ] && [ -d "models" ] && [ -d "reports" ]; then
    echo "✅ Ключевые директории присутствуют"
    SCORE=$((SCORE+1))
fi

# Проверка 8: Наличие Dockerfile
if [ -f "Dockerfile" ] || [ -f "Dockerfile.prod" ]; then
    echo "✅ Dockerfile существует"
    SCORE=$((SCORE+1))
fi

# Проверка 9: Наличие Kubernetes манифестов
if [ -d "k8s" ] && [ -f "k8s/deployment.yaml" ]; then
    echo "✅ Kubernetes манифесты существуют"
    SCORE=$((SCORE+1))
fi

# Проверка 10: Наличие CI/CD
if [ -d ".github/workflows" ] && [ -f ".github/workflows/deploy.yml" ]; then
    echo "✅ CI/CD пайплайн настроен"
    SCORE=$((SCORE+1))
fi

echo ""
echo "================================================="
echo "ИТОГ: $SCORE/$TOTAL"
if [ $SCORE -eq $TOTAL ]; then
    echo "🔥 ЛАБОРАТОРНАЯ РАБОТА 14 ВЫПОЛНЕНА! 🔥"
    echo "🎉 ПОЗДРАВЛЯЮ! ВСЕ 14 ЛАБОРАТОРНЫХ ГОТОВЫ! 🎉"
elif [ $SCORE -ge 8 ]; then
    echo "⚠️ Выполнено $SCORE из $TOTAL - почти готово"
else
    echo "❌ Выполнено $SCORE из $TOTAL - нужно доработать"
fi
echo "================================================="
