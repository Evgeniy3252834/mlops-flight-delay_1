#!/bin/bash

echo "================================================="
echo "🔥 ЧЕК-ЛИСТ ЛАБОРАТОРНОЙ РАБОТЫ 12 🔥"
echo "Детекция дрейфа и автоматическая реакция"
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

# Проверка 1: drift_check.py
if [ -f "src/drift_check.py" ]; then
    echo -e "${GREEN}✅ src/drift_check.py существует${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${RED}❌ src/drift_check.py не найден${NC}"
fi
TOTAL=$((TOTAL + 1))

# Проверка 2: generate_drift.py
if [ -f "src/generate_drift.py" ]; then
    echo -e "${GREEN}✅ src/generate_drift.py существует${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${RED}❌ src/generate_drift.py не найден${NC}"
fi
TOTAL=$((TOTAL + 1))

# Проверка 3: scheduler.py
if [ -f "src/scheduler.py" ]; then
    echo -e "${GREEN}✅ src/scheduler.py существует${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${RED}❌ src/scheduler.py не найден${NC}"
fi
TOTAL=$((TOTAL + 1))

# Проверка 4: DAG для дрейфа
if [ -f "airflow/dags/drift_detection_dag.py" ]; then
    echo -e "${GREEN}✅ DAG для дрейфа существует${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${RED}❌ DAG для дрейфа не найден${NC}"
fi
TOTAL=$((TOTAL + 1))

# Проверка 5: run_drift_check.bat
if [ -f "run_drift_check.bat" ]; then
    echo -e "${GREEN}✅ run_drift_check.bat существует${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${YELLOW}⚠️ run_drift_check.bat не найден (опционально)${NC}"
fi
TOTAL=$((TOTAL + 1))

echo ""
echo "📊 ПРОВЕРКА РАБОТОСПОСОБНОСТИ"
echo "-----------------------------"

# Проверка 6: Запуск без дрейфа
python src/drift_check.py > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ drift_check.py работает без ошибок${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${RED}❌ Ошибка при запуске drift_check.py${NC}"
fi
TOTAL=$((TOTAL + 1))

# Проверка 7: Генерация дрейфа
python src/generate_drift.py --intensity 0.3 > /dev/null 2>&1
if [ -f "data/processed/current_data.csv" ]; then
    echo -e "${GREEN}✅ Данные с дрейфом сгенерированы${NC}"
    SCORE=$((SCORE + 1))
    
    # Показываем первые строки
    echo "   📋 Первые 3 строки:"
    head -3 data/processed/current_data.csv | sed 's/^/   /'
else
    echo -e "${RED}❌ Данные с дрейфом не созданы${NC}"
fi
TOTAL=$((TOTAL + 1))

# Проверка 8: Отчет о дрейфе
python src/drift_check.py > /dev/null 2>&1
if [ -f "reports/drift_report.html" ] && [ -f "reports/drift_report.json" ]; then
    echo -e "${GREEN}✅ Отчеты о дрейфе созданы${NC}"
    SCORE=$((SCORE + 1))
    
    # Показываем результат
    if [ -f "reports/drift_report.json" ]; then
        DRIFT_DETECTED=$(grep -o '"retraining_triggered": true' reports/drift_report.json)
        if [ -n "$DRIFT_DETECTED" ]; then
            echo -e "   ${GREEN}🔴 Дрейф обнаружен!${NC}"
        else
            echo -e "   ${GREEN}🟢 Дрейф не обнаружен${NC}"
        fi
    fi
else
    echo -e "${RED}❌ Отчеты о дрейфе не найдены${NC}"
fi
TOTAL=$((TOTAL + 1))

# Проверка 9: Триггер переобучения
if [ -f "reports/retrain_trigger.txt" ] || grep -q "retraining_triggered" reports/drift_report.json 2>/dev/null; then
    echo -e "${GREEN}✅ Триггер переобучения работает${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${YELLOW}⚠️ Триггер переобучения не найден (опционально)${NC}"
fi
TOTAL=$((TOTAL + 1))

# Проверка 10: Логи
if [ -f "reports/drift_check.log" ] || [ -f "logs/drift_check.log" ]; then
    echo -e "${GREEN}✅ Логи дрейфа создаются${NC}"
    SCORE=$((SCORE + 1))
    
    # Размер лога
    if [ -f "reports/drift_check.log" ]; then
        LOG_SIZE=$(du -h reports/drift_check.log | cut -f1)
        echo "   📊 Размер лога: $LOG_SIZE"
    fi
else
    echo -e "${YELLOW}⚠️ Логи не найдены (опционально)${NC}"
fi
TOTAL=$((TOTAL + 1))

echo ""
echo "📋 ПРОВЕРКА GIT"
echo "---------------"

# Проверка 11: Git коммит
if git log --oneline | grep -q "lab12"; then
    echo -e "${GREEN}✅ Коммит лабораторной 12 найден${NC}"
    SCORE=$((SCORE + 1))
    
    # Последние коммиты
    echo "   📌 Последние коммиты:"
    git log --oneline -3 | sed 's/^/   • /'
else
    echo -e "${RED}❌ Коммит лабораторной 12 не найден${NC}"
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
echo "ИТОГИ ЛАБОРАТОРНОЙ РАБОТЫ 12"
echo "================================================="

# Подсчет процента
PERCENT=$((SCORE * 100 / TOTAL))

echo ""
echo "📊 Результат: $SCORE/$TOTAL ($PERCENT%)"
echo ""

if [ $PERCENT -ge 80 ]; then
    echo -e "${GREEN}🔥 ЛАБОРАТОРНАЯ РАБОТА 12 ВЫПОЛНЕНА! 🔥${NC}"
    echo -e "${GREEN}✅ Можно переходить к лабораторной 13${NC}"
    
    if [ $SCORE -eq $TOTAL ]; then
        echo -e "${GREEN}🌟 100% - ИДЕАЛЬНО! 🌟${NC}"
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
echo "   • Наличие скриптов для детекции дрейфа"
echo "   • Генерация тестовых данных с дрейфом"
echo "   • Создание отчетов (HTML/JSON)"
echo "   • Автоматический запуск переобучения"
echo "   • Логирование результатов"
echo "   • Интеграция с Airflow (опционально)"
echo "   • Git коммит и чистота"
echo "================================================="

# Советы
if [ $PERCENT -lt 100 ]; then
    echo ""
    echo "💡 Советы по улучшению:"
    
    if [ ! -f "src/drift_check.py" ]; then
        echo "   • Создай скрипт детекции дрейфа"
    fi
    
    if [ ! -f "data/processed/current_data.csv" ]; then
        echo "   • Сгенерируй данные с дрейфом: python src/generate_drift.py"
    fi
    
    if [ ! -f "reports/drift_report.html" ]; then
        echo "   • Запусти проверку дрейфа: python src/drift_check.py"
    fi
    
    if [ -n "$(git status --porcelain)" ]; then
        echo "   • Закоммить изменения: git add . && git commit -m 'lab12: final'"
    fi
fi
