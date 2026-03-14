#!/bin/bash

echo "================================================="
echo "🔥 ЧЕК-ЛИСТ ЛАБОРАТОРНОЙ РАБОТЫ 10 🔥"
echo "Деплой в Kubernetes (Minikube)"
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

# Проверка 1: Директория k8s
if [ -d "k8s" ]; then
    echo -e "${GREEN}✅ Директория k8s существует${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${RED}❌ Директория k8s не найдена${NC}"
fi
TOTAL=$((TOTAL + 1))

# Проверка 2: deployment.yaml
if [ -f "k8s/deployment.yaml" ]; then
    echo -e "${GREEN}✅ deployment.yaml существует${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${RED}❌ deployment.yaml не найден${NC}"
fi
TOTAL=$((TOTAL + 1))

# Проверка 3: hpa.yaml
if [ -f "k8s/hpa.yaml" ]; then
    echo -e "${GREEN}✅ hpa.yaml существует${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${RED}❌ hpa.yaml не найден${NC}"
fi
TOTAL=$((TOTAL + 1))

# Проверка 4: configmap.yaml
if [ -f "k8s/configmap.yaml" ]; then
    echo -e "${GREEN}✅ configmap.yaml существует${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${RED}❌ configmap.yaml не найден${NC}"
fi
TOTAL=$((TOTAL + 1))

# Проверка 5: deploy.sh
if [ -f "k8s/deploy.sh" ]; then
    echo -e "${GREEN}✅ deploy.sh существует${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${RED}❌ deploy.sh не найден${NC}"
fi
TOTAL=$((TOTAL + 1))

# Проверка 6: cleanup.sh
if [ -f "k8s/cleanup.sh" ]; then
    echo -e "${GREEN}✅ cleanup.sh существует${NC}"
    SCORE=$((SCORE + 1))
else
    echo -e "${RED}❌ cleanup.sh не найден${NC}"
fi
TOTAL=$((TOTAL + 1))

echo ""
echo "🚀 ПРОВЕРКА MINIKUBE"
echo "-------------------"

# Проверка 7: Minikube установлен
if command -v minikube &> /dev/null; then
    echo -e "${GREEN}✅ Minikube установлен${NC}"
    SCORE=$((SCORE + 1))
    
    # Проверка 8: Minikube запущен
    if minikube status | grep -q "Running"; then
        echo -e "${GREEN}✅ Minikube запущен${NC}"
        SCORE=$((SCORE + 1))
        
        # Проверка 9: kubectl работает
        if kubectl cluster-info &> /dev/null; then
            echo -e "${GREEN}✅ kubectl работает${NC}"
            SCORE=$((SCORE + 1))
        else
            echo -e "${RED}❌ kubectl не работает${NC}"
        fi
    else
        echo -e "${RED}❌ Minikube не запущен${NC}"
    fi
else
    echo -e "${RED}❌ Minikube не установлен${NC}"
fi
TOTAL=$((TOTAL + 3))

echo ""
echo "📦 ПРОВЕРКА ДЕПЛОЯ"
echo "------------------"

# Проверка 10: Deployment существует
if kubectl get deployment flight-delay-api &> /dev/null; then
    echo -e "${GREEN}✅ Deployment существует${NC}"
    SCORE=$((SCORE + 1))
    
    # Проверка реплик
    READY=$(kubectl get deployment flight-delay-api -o jsonpath='{.status.readyReplicas}')
    echo "   📊 Готовых реплик: $READY"
else
    echo -e "${RED}❌ Deployment не найден${NC}"
fi
TOTAL=$((TOTAL + 1))

# Проверка 11: Service существует
if kubectl get service flight-delay-api-service &> /dev/null; then
    echo -e "${GREEN}✅ Service существует${NC}"
    SCORE=$((SCORE + 1))
    
    # Тип сервиса
    TYPE=$(kubectl get service flight-delay-api-service -o jsonpath='{.spec.type}')
    echo "   📌 Тип: $TYPE"
else
    echo -e "${RED}❌ Service не найден${NC}"
fi
TOTAL=$((TOTAL + 1))

# Проверка 12: HPA существует
if kubectl get hpa flight-delay-api-hpa &> /dev/null; then
    echo -e "${GREEN}✅ HPA существует${NC}"
    SCORE=$((SCORE + 1))
    
    # Текущие метрики
    MIN=$(kubectl get hpa flight-delay-api-hpa -o jsonpath='{.spec.minReplicas}')
    MAX=$(kubectl get hpa flight-delay-api-hpa -o jsonpath='{.spec.maxReplicas}')
    echo "   📈 Реплики: от $MIN до $MAX"
else
    echo -e "${RED}❌ HPA не найден${NC}"
fi
TOTAL=$((TOTAL + 1))

# Проверка 13: Поды запущены
PODS=$(kubectl get pods -l app=flight-delay-api --field-selector status.phase=Running -o jsonpath='{.items[*].metadata.name}' | wc -w)
if [ $PODS -gt 0 ]; then
    echo -e "${GREEN}✅ Поды запущены: $PODS${NC}"
    SCORE=$((SCORE + 1))
    
    # Детали подов
    kubectl get pods -l app=flight-delay-api
else
    echo -e "${RED}❌ Поды не запущены${NC}"
fi
TOTAL=$((TOTAL + 1))

# Проверка 14: API доступен
if curl -s http://127.0.0.1:8080/health &> /dev/null; then
    echo -e "${GREEN}✅ API доступен по localhost:8080${NC}"
    SCORE=$((SCORE + 1))
    
    # Проверка health
    HEALTH=$(curl -s http://127.0.0.1:8080/health)
    echo "   📊 Health: $HEALTH"
else
    echo -e "${YELLOW}⚠️ API не доступен (возможно port-forward не запущен)${NC}"
fi
TOTAL=$((TOTAL + 1))

echo ""
echo "📋 ПРОВЕРКА GIT"
echo "---------------"

# Проверка 15: Git коммит
if git log --oneline | grep -q "lab10"; then
    echo -e "${GREEN}✅ Коммит лабораторной 10 найден${NC}"
    SCORE=$((SCORE + 1))
    
    # Последние коммиты
    echo "   📌 Последние коммиты:"
    git log --oneline -3 | sed 's/^/   • /'
else
    echo -e "${RED}❌ Коммит лабораторной 10 не найден${NC}"
fi
TOTAL=$((TOTAL + 1))

# Проверка 16: Чистота рабочей директории
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
echo "ИТОГИ ЛАБОРАТОРНОЙ РАБОТЫ 10"
echo "================================================="

# Подсчет процента
PERCENT=$((SCORE * 100 / TOTAL))

echo ""
echo "📊 Результат: $SCORE/$TOTAL ($PERCENT%)"
echo ""

if [ $PERCENT -ge 80 ]; then
    echo -e "${GREEN}🔥 ЛАБОРАТОРНАЯ РАБОТА 10 ВЫПОЛНЕНА! 🔥${NC}"
    echo -e "${GREEN}✅ Можно переходить к лабораторной 11${NC}"
    
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
echo "   • Наличие манифестов (deployment, hpa, configmap)"
echo "   • Скрипты для деплоя/очистки"
echo "   • Minikube запущен и работает"
echo "   • Deployment и Service созданы"
echo "   • Поды запущены и работают"
echo "   • API доступен и отвечает"
echo "   • Git коммит и чистота"
echo "================================================="

# Советы
if [ $PERCENT -lt 100 ]; then
    echo ""
    echo "💡 Советы по улучшению:"
    
    if ! kubectl get deployment flight-delay-api &> /dev/null; then
        echo "   • Запусти деплой: kubectl apply -f k8s/deployment.yaml"
    fi
    
    if ! curl -s http://127.0.0.1:8080/health &> /dev/null; then
        echo "   • Запусти port-forward: kubectl port-forward service/flight-delay-api-service 8080:80"
    fi
    
    if [ -n "$(git status --porcelain)" ]; then
        echo "   • Закоммить изменения: git add . && git commit -m 'lab10: final'"
    fi
fi
