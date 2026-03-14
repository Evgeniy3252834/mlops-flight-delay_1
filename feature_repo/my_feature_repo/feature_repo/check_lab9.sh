#!/bin/bash

echo "================================================="
echo "🔥 ЧЕК-ЛИСТ ЛАБОРАТОРНОЙ РАБОТЫ 9 🔥"
echo "Feature Store (Feast)"
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

echo "📁 ПРОВЕРКА СТРУКТУРЫ"
echo "------------------"

# Проверка 1: Директория feature_repo
if [ -d "feature_repo" ]; then
    echo -e "${GREEN}✅ Директория feature_repo существует${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${RED}❌ Директория feature_repo не найдена${NC}"
fi
TOTAL=$((TOTAL + 1))

# Проверка 2: Директория с данными
if [ -d "feature_repo/data" ] || [ -d "feature_repo/my_feature_repo/feature_repo/data" ]; then
    echo -e "${GREEN}✅ Директория с данными существует${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${RED}❌ Директория с данными не найдена${NC}"
fi
TOTAL=$((TOTAL + 1))

echo ""
echo "📄 ПРОВЕРКА ФАЙЛОВ"
echo "------------------"

# Проверка 3: feature_store.yaml
if [ -f "feature_repo/feature_store.yaml" ] || [ -f "feature_repo/my_feature_repo/feature_repo/feature_store.yaml" ]; then
    echo -e "${GREEN}✅ feature_store.yaml существует${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${RED}❌ feature_store.yaml не найден${NC}"
fi
TOTAL=$((TOTAL + 1))

# Проверка 4: definitions.py
if [ -f "feature_repo/definitions.py" ] || [ -f "feature_repo/my_feature_repo/feature_repo/definitions.py" ]; then
    echo -e "${GREEN}✅ definitions.py существует${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${RED}❌ definitions.py не найден${NC}"
fi
TOTAL=$((TOTAL + 1))

# Проверка 5: CSV файлы
if [ -f "feature_repo/data/carrier_stats.csv" ] || [ -f "feature_repo/my_feature_repo/feature_repo/data/carrier_stats.csv" ]; then
    echo -e "${GREEN}✅ CSV файлы с признаками существуют${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${RED}❌ CSV файлы не найдены${NC}"
fi
TOTAL=$((TOTAL + 1))

# Проверка 6: registry.db
if [ -f "feature_repo/data/registry.db" ] || [ -f "feature_repo/my_feature_repo/feature_repo/data/registry.db" ]; then
    echo -e "${GREEN}✅ registry.db создан (Feast инициализирован)${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${RED}❌ registry.db не найден${NC}"
fi
TOTAL=$((TOTAL + 1))

echo ""
echo "📊 ПРОВЕРКА FEATURE VIEWS"
echo "-----------------------"

# Проверка 7: Наличие feature views
FEATURE_VIEWS_CHECK=$(python -c "
import sys
try:
    from feast import FeatureStore
    if sys.platform == 'win32':
        paths = ['feature_repo/my_feature_repo/feature_repo', 'feature_repo']
    else:
        paths = ['feature_repo/my_feature_repo/feature_repo', 'feature_repo']
    
    found = False
    for path in paths:
        try:
            fs = FeatureStore(repo_path=path)
            views = fs.list_feature_views()
            if views:
                print(f'SUCCESS|{len(views)}|' + '|'.join([v.name for v in views]))
                found = True
                break
        except:
            continue
    
    if not found:
        print('FAIL|0|')
except Exception as e:
    print(f'ERROR|0|{str(e)}')
" 2>/dev/null)

if [[ $FEATURE_VIEWS_CHECK == SUCCESS* ]]; then
    COUNT=$(echo $FEATURE_VIEWS_CHECK | cut -d'|' -f2)
    NAMES=$(echo $FEATURE_VIEWS_CHECK | cut -d'|' -f3 | tr '|' '\n')
    echo -e "${GREEN}✅ Найдено feature views: $COUNT${NC}"
    echo "   📋 Список:"
    echo "$NAMES" | sed 's/^/   • /'
    SCORE=$((SCORE + 1))
else
    echo -e "${RED}❌ Feature views не найдены${NC}"
fi
TOTAL=$((TOTAL + 1))

# Проверка 8: Проверка конкретных feature views
EXPECTED_VIEWS=("carrier_statistics" "airport_statistics" "hourly_statistics")
FOUND_VIEWS=$(echo $FEATURE_VIEWS_CHECK | cut -d'|' -f3)
VIEWS_OK=0

for view in "${EXPECTED_VIEWS[@]}"; do
    if [[ $FOUND_VIEWS == *"$view"* ]]; then
        VIEWS_OK=$((VIEWS_OK + 1))
    fi
done

if [ $VIEWS_OK -eq 3 ]; then
    echo -e "${GREEN}✅ Все три feature view найдены${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${YELLOW}⚠️ Найдено $VIEWS_OK из 3 feature views${NC}"
fi
TOTAL=$((TOTAL + 1))

echo ""
echo "🤖 ПРОВЕРКА ТРЕНИРОВКИ С FEATURE STORE"
echo "-------------------------------------"

# Проверка 9: Скрипт для обучения с фичами
if [ -f "src/train_with_features.py" ]; then
    echo -e "${GREEN}✅ train_with_features.py существует${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${RED}❌ train_with_features.py не найден${NC}"
fi
TOTAL=$((TOTAL + 1))

# Проверка 10: Модель с фичами
if [ -f "models/model_with_features.joblib" ]; then
    echo -e "${GREEN}✅ Модель с Feature Store обучена${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${YELLOW}⚠️ Модель с Feature Store не найдена (опционально)${NC}"
fi
TOTAL=$((TOTAL + 1))

echo ""
echo "📋 ПРОВЕРКА GIT"
echo "---------------"

# Проверка 11: Git коммит
if git log --oneline | grep -q "lab9"; then
    echo -e "${GREEN}✅ Коммит лабораторной 9 найден${NC}"
    SCORE=$((SCORE + 1))
    
    # Показываем последние коммиты
    echo "   Последние коммиты:"
    git log --oneline -3 | sed 's/^/   • /'
else
    echo -e "${RED}❌ Коммит лабораторной 9 не найден${NC}"
fi
TOTAL=$((TOTAL + 1))

# Проверка 12: Чистота рабочей директории
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
echo "ИТОГИ ЛАБОРАТОРНОЙ РАБОТЫ 9"
echo "================================================="

# Подсчет процента
PERCENT=$((SCORE * 100 / TOTAL))

echo ""
echo "📊 Результат: $SCORE/$TOTAL ($PERCENT%)"
echo ""

if [ $PERCENT -ge 80 ]; then
    echo -e "${GREEN}🔥 ЛАБОРАТОРНАЯ РАБОТА 9 ВЫПОЛНЕНА! 🔥${NC}"
    echo -e "${GREEN}✅ Можно переходить к лабораторной 10${NC}"
    
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
echo "   • Наличие структуры Feast (feature_repo)"
echo "   • Создание definitions.py с фичами"
echo "   • CSV файлы с признаками"
echo "   • Инициализация Feast (registry.db)"
echo "   • Feature views (carrier/airport/hourly)"
echo "   • Скрипт обучения с Feature Store"
echo "   • Git коммит и чистота"
echo "================================================="

# Советы
if [ $PERCENT -lt 100 ]; then
    echo ""
    echo "💡 Советы по улучшению:"
    
    if [ ! -f "src/train_with_features.py" ]; then
        echo "   • Создай скрипт обучения с Feature Store"
    fi
    
    if ! python -c "from feast import FeatureStore; fs=FeatureStore(repo_path='feature_repo/my_feature_repo/feature_repo'); fs.list_feature_views()" 2>/dev/null; then
        echo "   • Проверь что Feast apply выполнен"
    fi
    
    if [ -n "$(git status --porcelain)" ]; then
        echo "   • Закоммить все изменения"
    fi
fi
