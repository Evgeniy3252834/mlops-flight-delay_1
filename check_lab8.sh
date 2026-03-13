#!/bin/bash

echo "================================================="
echo "🔥 ЧЕК-ЛИСТ ЛАБОРАТОРНОЙ РАБОТЫ 8 🔥"
echo "Оркестрация пайплайна (Airflow)"
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

# Проверка 1: Директория airflow
if [ -d "airflow" ]; then
    echo -e "${GREEN}✅ Директория airflow существует${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${RED}❌ Директория airflow не найдена${NC}"
fi
TOTAL=$((TOTAL + 1))

# Проверка 2: Директория dags
if [ -d "airflow/dags" ]; then
    echo -e "${GREEN}✅ Директория airflow/dags существует${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${RED}❌ Директория airflow/dags не найдена${NC}"
fi
TOTAL=$((TOTAL + 1))

# Проверка 3: Директория logs
if [ -d "airflow/logs" ]; then
    echo -e "${GREEN}✅ Директория airflow/logs существует${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${RED}❌ Директория airflow/logs не найдена${NC}"
fi
TOTAL=$((TOTAL + 1))

# Проверка 4: Директория plugins
if [ -d "airflow/plugins" ]; then
    echo -e "${GREEN}✅ Директория airflow/plugins существует${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${RED}❌ Директория airflow/plugins не найдена${NC}"
fi
TOTAL=$((TOTAL + 1))

echo ""
echo "📄 ПРОВЕРКА ФАЙЛОВ"
echo "------------------"

# Проверка 5: DAG файл
if [ -f "airflow/dags/flight_pipeline.py" ]; then
    echo -e "${GREEN}✅ DAG файл существует: flight_pipeline.py${NC}"
    SCORE=$((SCORE + 1))
    
    # Проверяем наличие задач в DAG
    TASKS=$(grep -c "task_id" airflow/dags/flight_pipeline.py)
    echo "   📊 Количество задач в DAG: $TASKS"
else
    echo -e "${RED}❌ DAG файл не найден${NC}"
fi
TOTAL=$((TOTAL + 1))

# Проверка 6: Тестовый DAG
if [ -f "airflow/dags/test_dag.py" ]; then
    echo -e "${GREEN}✅ Тестовый DAG существует: test_dag.py${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${YELLOW}⚠️ Тестовый DAG не найден (опционально)${NC}"
fi
TOTAL=$((TOTAL + 1))

# Проверка 7: Docker Compose файл
if [ -f "docker-compose-airflow.yml" ]; then
    echo -e "${GREEN}✅ Docker Compose файл существует${NC}"
    SCORE=$((SCORE + 1))
    
    # Проверяем наличие сервисов
    SERVICES=$(grep -c "service:" docker-compose-airflow.yml)
    echo "   📦 Количество сервисов: $SERVICES"
else
    echo -e "${RED}❌ Docker Compose файл не найден${NC}"
fi
TOTAL=$((TOTAL + 1))

# Проверка 8: .env файл
if [ -f "airflow/.env" ]; then
    echo -e "${GREEN}✅ .env файл существует${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${RED}❌ .env файл не найден${NC}"
fi
TOTAL=$((TOTAL + 1))

# Проверка 9: start_airflow.sh
if [ -f "start_airflow.sh" ]; then
    echo -e "${GREEN}✅ start_airflow.sh существует${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${RED}❌ start_airflow.sh не найден${NC}"
fi
TOTAL=$((TOTAL + 1))

# Проверка 10: stop_airflow.sh
if [ -f "stop_airflow.sh" ]; then
    echo -e "${GREEN}✅ stop_airflow.sh существует${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${RED}❌ stop_airflow.sh не найден${NC}"
fi
TOTAL=$((TOTAL + 1))

echo ""
echo "🐳 ПРОВЕРКА ЗАПУСКА"
echo "------------------"

# Проверка 11: Docker установлен
if command -v docker &> /dev/null; then
    echo -e "${GREEN}✅ Docker установлен${NC}"
    SCORE=$((SCORE + 1))
    
    # Проверка 12: Airflow контейнеры запущены
    if docker ps | grep -q "airflow"; then
        echo -e "${GREEN}✅ Airflow контейнеры запущены${NC}"
        SCORE=$((SCORE + 1))
        
        # Показываем запущенные контейнеры
        echo "   Запущенные контейнеры:"
        docker ps --format "table {{.Names}}\t{{.Status}}" | grep airflow
    else
        echo -e "${YELLOW}⚠️ Airflow не запущен (запусти: ./start_airflow.sh)${NC}"
    fi
else
    echo -e "${RED}❌ Docker не установлен${NC}"
fi
TOTAL=$((TOTAL + 2))

echo ""
echo "📊 ПРОВЕРКА DAG"
echo "---------------"

# Проверка 13: Синтаксис DAG
if [ -f "airflow/dags/flight_pipeline.py" ]; then
    python -m py_compile airflow/dags/flight_pipeline.py 2>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Синтаксис DAG корректен${NC}"
        SCORE=$((SCORE + 1))
    else
        echo -e "${RED}❌ Ошибки синтаксиса в DAG${NC}"
    fi
else
    echo -e "${RED}❌ DAG не найден для проверки синтаксиса${NC}"
fi
TOTAL=$((TOTAL + 1))

echo ""
echo "📋 ПРОВЕРКА GIT"
echo "---------------"

# Проверка 14: Git коммит
if git log --oneline | grep -q "lab8"; then
    echo -e "${GREEN}✅ Коммит лабораторной 8 найден${NC}"
    SCORE=$((SCORE + 1))
    
    # Показываем последние коммиты
    echo "   Последние коммиты:"
    git log --oneline -3 | sed 's/^/   • /'
else
    echo -e "${RED}❌ Коммит лабораторной 8 не найден${NC}"
fi
TOTAL=$((TOTAL + 1))

# Проверка 15: Чистота рабочей директории
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
echo "ИТОГИ ЛАБОРАТОРНОЙ РАБОТЫ 8"
echo "================================================="

# Подсчет процента
PERCENT=$((SCORE * 100 / TOTAL))

echo ""
echo "📊 Результат: $SCORE/$TOTAL ($PERCENT%)"
echo ""

if [ $PERCENT -ge 80 ]; then
    echo -e "${GREEN}🔥 ЛАБОРАТОРНАЯ РАБОТА 8 ВЫПОЛНЕНА! 🔥${NC}"
    echo -e "${GREEN}✅ Можно переходить к лабораторной 9${NC}"
    
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
echo "   • Наличие структуры директорий Airflow"
echo "   • Создание DAG файла с задачами"
echo "   • Docker Compose конфигурация"
echo "   • Скрипты для запуска/остановки"
echo "   • Возможность запуска пайплайна"
echo "   • Git коммит и чистота"
echo "================================================="

# Советы
if [ $SCORE -lt $TOTAL ]; then
    echo ""
    echo "💡 Советы по улучшению:"
    
    if [ ! -f "airflow/dags/test_dag.py" ]; then
        echo "   • Создай тестовый DAG для проверки"
    fi
    
    if ! docker ps | grep -q "airflow"; then
        echo "   • Запусти Airflow: ./start_airflow.sh"
    fi
    
    if [ -n "$(git status --porcelain)" ]; then
        echo "   • Закоммить все изменения"
    fi
fi
