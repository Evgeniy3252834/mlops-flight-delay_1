#!/bin/bash

echo "================================================="
echo "🔥 ЧЕК-ЛИСТ ЛАБОРАТОРНОЙ РАБОТЫ 5 🔥"
echo "Оценка модели и регистрация в Model Registry"
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

# Функция проверки
check() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
        SCORE=$((SCORE + 1))
    else
        echo -e "${RED}❌ $2${NC}"
    fi
    TOTAL=$((TOTAL + 1))
}

echo "📁 ПРОВЕРКА ФАЙЛОВ"
echo "------------------"

# Проверка 1: Скрипт оценки
if [ -f "src/evaluate.py" ]; then
    echo -e "${GREEN}✅ Скрипт оценки найден: src/evaluate.py${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${RED}❌ Скрипт оценки не найден${NC}"
fi
TOTAL=$((TOTAL + 1))

# Проверка 2: Директория reports
if [ -d "reports" ]; then
    echo -e "${GREEN}✅ Директория reports существует${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${RED}❌ Директория reports не найдена${NC}"
fi
TOTAL=$((TOTAL + 1))

# Проверка 3: Директория figures
if [ -d "reports/figures" ]; then
    echo -e "${GREEN}✅ Директория reports/figures существует${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${RED}❌ Директория reports/figures не найдена${NC}"
fi
TOTAL=$((TOTAL + 1))

echo ""
echo "📊 ПРОВЕРКА ОТЧЕТОВ"
echo "------------------"

# Проверка 4: Файл с метриками
if [ -f "reports/metrics_detailed.json" ]; then
    echo -e "${GREEN}✅ metrics_detailed.json существует${NC}"
    SCORE=$((SCORE + 1))
    
    # Покажем метрики
    echo "   📈 Содержимое:"
    if command -v jq &> /dev/null; then
        cat reports/metrics_detailed.json | jq '.'
    else
        cat reports/metrics_detailed.json | grep -E "accuracy|roc_auc|precision|recall|f1"
    fi
else
    echo -e "${RED}❌ metrics_detailed.json не найден${NC}"
fi
TOTAL=$((TOTAL + 1))

# Проверка 5: Матрица ошибок
if [ -f "reports/figures/confusion_matrix.png" ]; then
    echo -e "${GREEN}✅ confusion_matrix.png создан${NC}"
    SCORE=$((SCORE + 1))
    
    # Размер файла
    SIZE=$(du -h "reports/figures/confusion_matrix.png" | cut -f1)
    echo "   📊 Размер: $SIZE"
else
    echo -e "${RED}❌ confusion_matrix.png не найден${NC}"
fi
TOTAL=$((TOTAL + 1))

# Проверка 6: ROC-кривая (опционально)
if [ -f "reports/figures/roc_curve.png" ]; then
    echo -e "${GREEN}✅ roc_curve.png создан${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${YELLOW}⚠️ roc_curve.png не найден (опционально)${NC}"
fi
TOTAL=$((TOTAL + 1))

# Проверка 7: Важность признаков (опционально)
if [ -f "reports/figures/feature_importance.png" ]; then
    echo -e "${GREEN}✅ feature_importance.png создан${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${YELLOW}⚠️ feature_importance.png не найден (опционально)${NC}"
fi
TOTAL=$((TOTAL + 1))

echo ""
echo "📋 ПРОВЕРКА МЕТРИК"
echo "------------------"

# Проверка 8: Значения метрик
if [ -f "reports/metrics_detailed.json" ]; then
    ACCURACY=$(grep -o '"accuracy": [0-9.]*' reports/metrics_detailed.json | cut -d' ' -f2)
    ROC_AUC=$(grep -o '"roc_auc": [0-9.]*' reports/metrics_detailed.json | cut -d' ' -f2)
    
    echo "   📊 Accuracy: $ACCURACY"
    echo "   📊 ROC-AUC: $ROC_AUC"
    
    if (( $(echo "$ACCURACY > 0" | bc -l) )); then
        echo -e "${GREEN}✅ Метрики имеют корректные значения${NC}"
        SCORE=$((SCORE + 1))
    else
        echo -e "${RED}❌ Метрики некорректны${NC}"
    fi
else
    echo -e "${RED}❌ Невозможно проверить метрики${NC}"
fi
TOTAL=$((TOTAL + 1))

echo ""
echo "🤖 ПРОВЕРКА MODEL REGISTRY"
echo "-------------------------"

# Проверка 9: Регистрация модели
if command -v python &> /dev/null; then
    python -c "
import mlflow
from mlflow.tracking import MlflowClient
mlflow.set_tracking_uri('sqlite:///mlflow.db')
client = MlflowClient()
models = client.search_registered_models()
if models:
    print('✅ Модели зарегистрированы:')
    for model in models:
        print(f'   📦 {model.name}')
        for version in model.latest_versions:
            print(f'      • v{version.version} - {version.current_stage}')
    exit(0)
else:
    print('❌ Модели не зарегистрированы')
    exit(1)
" 2>/dev/null
    if [ $? -eq 0 ]; then
        SCORE=$((SCORE + 1))
    fi
else
    echo -e "${YELLOW}⚠️ Python не найден, пропускаем проверку Registry${NC}"
fi
TOTAL=$((TOTAL + 1))

echo ""
echo "📊 ПРОВЕРКА GIT"
echo "---------------"

# Проверка 10: Git коммит
if git log --oneline | grep -q "lab5"; then
    echo -e "${GREEN}✅ Коммит лабораторной 5 найден${NC}"
    SCORE=$((SCORE + 1))
    
    # Покажем последние коммиты
    echo "   Последние коммиты:"
    git log --oneline -3 | sed 's/^/   • /'
else
    echo -e "${RED}❌ Коммит лабораторной 5 не найден${NC}"
fi
TOTAL=$((TOTAL + 1))

# Проверка 11: Чистота рабочей директории
if [ -z "$(git status --porcelain)" ]; then
    echo -e "${GREEN}✅ Рабочая директория чиста${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${RED}❌ Есть незакоммиченные изменения${NC}"
    echo ""
    git status -s
fi
TOTAL=$((TOTAL + 1))

echo ""
echo "================================================="
echo "ИТОГИ ЛАБОРАТОРНОЙ РАБОТЫ 5"
echo "================================================="

# Подсчет процента
PERCENT=$((SCORE * 100 / TOTAL))

echo ""
echo "📊 Результат: $SCORE/$TOTAL ($PERCENT%)"
echo ""

if [ $PERCENT -ge 80 ]; then
    echo -e "${GREEN}🔥 ЛАБОРАТОРНАЯ РАБОТА 5 ВЫПОЛНЕНА! 🔥${NC}"
    echo -e "${GREEN}✅ Можно переходить к лабораторной 6${NC}"
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
echo "   • Наличие скрипта evaluate.py"
echo "   • Создание отчетов с метриками"
echo "   • Визуализации (матрица ошибок)"
echo "   • Корректные значения метрик"
echo "   • Регистрация модели в Registry"
echo "   • Git коммит"
echo "================================================="
