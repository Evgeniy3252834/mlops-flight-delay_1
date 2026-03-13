#!/bin/bash

echo "================================================="
echo "🔥 ЧЕК-ЛИСТ ЛАБОРАТОРНОЙ РАБОТЫ 11 🔥"
echo "Мониторинг (Prometheus + Grafana)"
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

# Проверка 1: API с метриками
if grep -q "prometheus_client" src/api.py 2>/dev/null; then
    echo -e "${GREEN}✅ API содержит метрики Prometheus${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${RED}❌ Метрики не найдены в API${NC}"
fi
TOTAL=$((TOTAL + 1))

# Проверка 2: prometheus.yml
if [ -f "prometheus.yml" ]; then
    echo -e "${GREEN}✅ prometheus.yml существует${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${RED}❌ prometheus.yml не найден${NC}"
fi
TOTAL=$((TOTAL + 1))

# Проверка 3: docker-compose-monitoring.yml
if [ -f "docker-compose-monitoring.yml" ]; then
    echo -e "${GREEN}✅ docker-compose-monitoring.yml существует${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${YELLOW}⚠️ docker-compose-monitoring.yml не найден (опционально)${NC}"
fi
TOTAL=$((TOTAL + 1))

# Проверка 4: Grafana конфиги
if [ -d "grafana" ] && [ -f "grafana/datasources/datasource.yml" ]; then
    echo -e "${GREEN}✅ Grafana конфиги существуют${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${YELLOW}⚠️ Grafana конфиги не найдены (опционально)${NC}"
fi
TOTAL=$((TOTAL + 1))

echo ""
echo "🐳 ПРОВЕРКА КОНТЕЙНЕРОВ"
echo "----------------------"

# Проверка 5: Prometheus контейнер
if docker ps | grep -q "prometheus"; then
    echo -e "${GREEN}✅ Prometheus контейнер запущен${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${RED}❌ Prometheus контейнер не запущен${NC}"
fi
TOTAL=$((TOTAL + 1))

# Проверка 6: Grafana контейнер
if docker ps | grep -q "grafana"; then
    echo -e "${GREEN}✅ Grafana контейнер запущен${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${RED}❌ Grafana контейнер не запущен${NC}"
fi
TOTAL=$((TOTAL + 1))

echo ""
echo "🌐 ПРОВЕРКА ЭНДПОИНТОВ"
echo "---------------------"

# Проверка 7: API метрики доступны
if curl -s http://127.0.0.1:8080/metrics | grep -q "python_info"; then
    echo -e "${GREEN}✅ Метрики API доступны по /metrics${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${RED}❌ Метрики API не доступны${NC}"
fi
TOTAL=$((TOTAL + 1))

# Проверка 8: Prometheus UI доступен
if curl -s http://127.0.0.1:9090 > /dev/null; then
    echo -e "${GREEN}✅ Prometheus UI доступен (http://localhost:9090)${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${RED}❌ Prometheus UI не доступен${NC}"
fi
TOTAL=$((TOTAL + 1))

# Проверка 9: Grafana UI доступен
if curl -s http://127.0.0.1:3000 > /dev/null; then
    echo -e "${GREEN}✅ Grafana UI доступен (http://localhost:3000)${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${RED}❌ Grafana UI не доступен${NC}"
fi
TOTAL=$((TOTAL + 1))

echo ""
echo "📊 ПРОВЕРКА МЕТРИК"
echo "------------------"

# Проверка 10: Метрики в Prometheus
if curl -s "http://127.0.0.1:9090/api/v1/query?query=up" | grep -q "success"; then
    echo -e "${GREEN}✅ Prometheus собирает метрики${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${RED}❌ Prometheus не собирает метрики${NC}"
fi
TOTAL=$((TOTAL + 1))

echo ""
echo "📋 ПРОВЕРКА GIT"
echo "---------------"

# Проверка 11: Git коммит
if git log --oneline | grep -q "lab11"; then
    echo -e "${GREEN}✅ Коммит лабораторной 11 найден${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${RED}❌ Коммит лабораторной 11 не найден${NC}"
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
echo "ИТОГИ ЛАБОРАТОРНОЙ РАБОТЫ 11"
echo "================================================="

PERCENT=$((SCORE * 100 / TOTAL))
echo "📊 Результат: $SCORE/$TOTAL ($PERCENT%)"

if [ $PERCENT -ge 80 ]; then
    echo -e "${GREEN}🔥 ЛАБОРАТОРНАЯ РАБОТА 11 ВЫПОЛНЕНА! 🔥${NC}"
elif [ $PERCENT -ge 60 ]; then
    echo -e "${YELLOW}⚠️ Выполнено частично${NC}"
else
    echo -e "${RED}❌ Нужно дорабатывать${NC}"
fi
echo "================================================="
