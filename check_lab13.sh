#!/bin/bash

echo "================================================="
echo "🔥 ЧЕК-ЛИСТ ЛАБОРАТОРНОЙ РАБОТЫ 13 🔥"
echo "Полный CI/CD: от кода до обновления кластера"
echo "================================================="
echo ""

# Счетчик
TOTAL=0
SCORE=0

# Цвета
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "📁 ПРОВЕРКА ФАЙЛОВ"
echo "------------------"

# Проверка 1: GitHub Actions workflows
if [ -f ".github/workflows/deploy.yml" ] && [ -f ".github/workflows/test.yml" ]; then
    echo -e "${GREEN}✅ GitHub Actions workflows существуют${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${RED}❌ GitHub Actions workflows не найдены${NC}"
fi
TOTAL=$((TOTAL + 1))

# Проверка 2: Dockerfile.prod
if [ -f "Dockerfile.prod" ]; then
    echo -e "${GREEN}✅ Dockerfile.prod существует${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${RED}❌ Dockerfile.prod не найден${NC}"
fi
TOTAL=$((TOTAL + 1))

# Проверка 3: Production деплой
if [ -f "k8s/deployment-prod.yaml" ]; then
    echo -e "${GREEN}✅ Production Kubernetes манифест существует${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${RED}❌ Production манифест не найден${NC}"
fi
TOTAL=$((TOTAL + 1))

# Проверка 4: Скрипты для CI/CD
if [ -d "scripts" ] && [ -f "scripts/get-kubeconfig.sh" ] && [ -f "scripts/test-cicd-local.sh" ]; then
    echo -e "${GREEN}✅ Скрипты для CI/CD существуют${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${RED}❌ Скрипты не найдены${NC}"
fi
TOTAL=$((TOTAL + 1))

# Проверка 5: README для CI/CD
if [ -f "CICD_README.md" ]; then
    echo -e "${GREEN}✅ CICD_README.md существует${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${RED}❌ CICD_README.md не найден${NC}"
fi
TOTAL=$((TOTAL + 1))

echo ""
echo "📋 ПРОВЕРКА GIT"
echo "---------------"

# Проверка 6: Git коммит
if git log --oneline | grep -q "lab13"; then
    echo -e "${GREEN}✅ Коммит лабораторной 13 найден${NC}"
    SCORE=$((SCORE + 1))
    
    # Последние коммиты
    echo "   📌 Последние коммиты:"
    git log --oneline -3 | sed 's/^/   • /'
else
    echo -e "${RED}❌ Коммит лабораторной 13 не найден${NC}"
fi
TOTAL=$((TOTAL + 1))

# Проверка 7: Чистота рабочей директории
if [ -z "$(git status --porcelain)" ]; then
    echo -e "${GREEN}✅ Рабочая директория чиста${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${RED}❌ Есть незакоммиченные изменения${NC}"
    git status -s
fi
TOTAL=$((TOTAL + 1))

echo ""
echo "================================================="
echo "ИТОГИ ЛАБОРАТОРНОЙ РАБОТЫ 13"
echo "================================================="

# Подсчет процента
PERCENT=$((SCORE * 100 / TOTAL))

echo ""
echo "📊 Результат: $SCORE/$TOTAL ($PERCENT%)"
echo ""

if [ $PERCENT -ge 80 ]; then
    echo -e "${GREEN}🔥 ЛАБОРАТОРНАЯ РАБОТА 13 ВЫПОЛНЕНА! 🔥${NC}"
    echo -e "${GREEN}✅ Можно переходить к лабораторной 14${NC}"
    
    if [ $SCORE -eq $TOTAL ]; then
        echo -e "${GREEN}🌟 100% - ОТЛИЧНАЯ РАБОТА! 🌟${NC}"
    fi
elif [ $PERCENT -ge 60 ]; then
    echo -e "${YELLOW}⚠️ Лабораторная работа выполнена частично${NC}"
    echo -e "${YELLOW}⚠️ Доделай недостающие пункты${NC}"
else
    echo -e "${RED}❌ Лабораторная работа не зачтена${NC}"
    echo -e "${RED}❌ Нужно дорабатывать${NC}"
fi
echo "================================================="

# Детали по критериям
echo ""
echo "📋 КРИТЕРИИ ОЦЕНКИ:"
echo "   • Наличие GitHub Actions workflows (deploy.yml, test.yml)"
echo "   • Dockerfile для production"
echo "   • Kubernetes манифесты для прода"
echo "   • Скрипты для CI/CD (get-kubeconfig, test-cicd-local)"
echo "   • Документация (CICD_README.md)"
echo "   • Git коммит и чистота"
echo "================================================="

# Советы
if [ $PERCENT -lt 100 ]; then
    echo ""
    echo "💡 Советы по улучшению:"
    
    if [ ! -f ".github/workflows/deploy.yml" ]; then
        echo "   • Создай deploy.yml"
    fi
    
    if [ ! -f "Dockerfile.prod" ]; then
        echo "   • Создай Dockerfile.prod"
    fi
    
    if [ ! -f "CICD_README.md" ]; then
        echo "   • Создай CICD_README.md"
    fi
    
    if [ -n "$(git status --porcelain)" ]; then
        echo "   • Закоммить изменения: git add . && git commit -m 'lab13: final'"
    fi
fi
