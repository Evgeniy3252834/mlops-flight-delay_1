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
    echo -e "${YELLOW}⚠️ DAG для дрейфа не найден (опционально)${NC}"
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

# Проверка 6: Запуск без ошибок
python src/drift_check.py > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ drift_check.py работает без ошибок${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${RED}❌ Ошибка при запуске drift_check.py${NC}"
fi
TOTAL=$((TOTAL + 1))

# Проверка 7: Генерация дрейфа
if [ -f "data/processed/current_data.csv" ]; then
    echo -e "${GREEN}✅ Данные с дрейфом сгенерированы${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${RED}❌ Данные с дрейфом не созданы${NC}"
fi
TOTAL=$((TOTAL + 1))

# Проверка 8: Отчет о дрейфе JSON
if [ -f "reports/drift_report.json" ]; then
    echo -e "${GREEN}✅ Отчет о дрейфе найден (drift_report.json)${NC}"
    SCORE=$((SCORE + 1))
    
    # Показываем содержимое
    echo "   📋 Содержимое отчета:"
    cat reports/drift_report.json | sed 's/^/   /'
else
    echo -e "${RED}❌ Отчет о дрейфе не найден${NC}"
fi
TOTAL=$((TOTAL + 1))

# Проверка 9: Логи
if [ -f "reports/drift_check.log" ] || [ -f "logs/drift_check.log" ]; then
    echo -e "${GREEN}✅ Логи дрейфа создаются${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${YELLOW}⚠️ Логи не найдены (опционально)${NC}"
fi
TOTAL=$((TOTAL + 1))

# Проверка 10: Триггер переобучения (по факту выполнения)
if grep -q "drift_detected.*true" reports/drift_report.json 2>/dev/null; then
    echo -e "${GREEN}✅ Дрейф обнаружен, переобучение запущено${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${YELLOW}⚠️ Дрейф не обнаружен или переобучение не запускалось${NC}"
fi
TOTAL=$((TOTAL + 1))

echo ""
echo "📋 ПРОВЕРКА GIT"
echo "---------------"

# Проверка 11: Git коммит
if git log --oneline | grep -q "lab12"; then
    echo -e "${GREEN}✅ Коммит лабораторной 12 найден${NC}"
    SCORE=$((SCORE + 1))
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
elif [ $PERCENT -ge 60 ]; then
    echo -e "${YELLOW}⚠️ Лабораторная работа выполнена частично${NC}"
else
    echo -e "${RED}❌ Лабораторная работа не зачтена${NC}"
fi
echo "================================================="
