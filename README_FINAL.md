# MLOps Flight Delay Prediction Project

## 🚀 Полный пайплайн MLOps

### Архитектура проекта
┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│ Данные │───▶│ DVC │───▶│ Предобр-ка │
│ (raw CSV) │ │ версионир-е │ │ │
└─────────────┘ └─────────────┘ └─────────────┘
│
▼
┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│ MLflow │◀───│ Обучение │◀───│ Feast │
│ Registry │ │ модели │ │ Feature Store│
└─────────────┘ └─────────────┘ └─────────────┘
│ │ │
▼ ▼ ▼
┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│ FastAPI │ │ Airflow │ │ Prometheus │
│ REST │ │ оркестрация │ │ мониторинг │
└─────────────┘ └─────────────┘ └─────────────┘
│ │ │
└──────────────────┼───────────────────┘
▼
┌─────────────────┐
│ Kubernetes │
│ (Minikube) │
└─────────────────┘
│
▼
┌─────────────────┐
│ CI/CD │
│ (GitHub Actions)│
└─────────────────┘

text

## 📋 Инструкция по воспроизведению

### 1. Клонирование и настройка окружения

```bash
# Клонировать репозиторий
git clone https://github.com/Evgeniy3252834/mlops-flight-delay.git
cd mlops-flight-delay

# Создать и активировать окружение
conda create -n mlops python=3.10 -y
conda activate mlops

# Установить зависимости
pip install -r requirements.txt
2. Получение данных (DVC)
bash
# Инициализировать DVC remote (если нужно)
dvc remote default local_remote
dvc pull
3. Запуск пайплайна предобработки
bash
# Запустить DVC пайплайн
dvc repro

# Проверить результаты
ls -la data/processed/
4. Обучение модели и MLflow
bash
# Обучить модель
python src/train.py --model_type random_forest --n_estimators 100 --max_depth 10

# Запустить MLflow UI
mlflow ui --port 5000
# Открыть http://localhost:5000
5. Feature Store (Feast)
bash
# Запустить Feast
cd feature_repo/my_feature_repo/feature_repo
feast apply
feast materialize-incremental $(date +"%Y-%m-%d")
cd ../..

# Обучить модель с фичами
python src/train_with_features.py
6. Запуск API
bash
# Локально
python src/api.py

# В Docker
docker build -t flight-delay-api .
docker run -p 8080:8080 flight-delay-api
7. Оркестрация с Airflow
bash
# Запустить Airflow
cd airflow
docker-compose up -d
# Открыть http://localhost:8081 (admin/admin)
8. Деплой в Kubernetes
bash
# Запустить Minikube
minikube start --driver=docker

# Настроить окружение Docker
eval $(minikube docker-env)

# Собрать образ
docker build -t flight-delay-api:latest .

# Деплой
kubectl apply -f k8s/

# Получить URL
minikube service flight-delay-api-service --url
9. Мониторинг
bash
# Запустить Prometheus и Grafana
docker run -d --name prometheus -p 9090:9090 -v $(pwd)/prometheus.yml:/etc/prometheus/prometheus.yml prom/prometheus
docker run -d --name grafana -p 3000:3000 grafana/grafana

# Открыть
# Prometheus: http://localhost:9090
# Grafana: http://localhost:3000 (admin/admin)
10. Детекция дрейфа
bash
# Сгенерировать данные с дрейфом
python src/generate_drift.py --intensity 0.5

# Запустить проверку
python src/drift_check.py
🔧 Возможные проблемы и их решение
Проблема	Решение
Docker не запускается	Запустите Docker Desktop
Minikube не стартует	minikube delete && minikube start
Port already in use	Измените порт или остановите процесс
DVC remote error	dvc remote default local_remote
📊 Демонстрация работы
Проверка API
bash
curl -X POST "http://localhost:8080/predict" \
  -H "Content-Type: application/json" \
  -d '{
    "carrier": "AA",
    "origin": "JFK",
    "dest": "LAX",
    "dep_time": 930,
    "distance": 2475,
    "flight_date": "2023-06-15"
  }'
Проверка метрик
bash
curl http://localhost:8080/metrics
Проверка здоровья
bash
curl http://localhost:8080/health
📈 Метрики модели
Accuracy: 0.95

ROC-AUC: 0.98

Precision: 0.94

Recall: 0.96

F1-Score: 0.95

🏗️ Принятые архитектурные решения
Компонент	Технология	Обоснование
Версионирование данных	DVC	Легкий, интеграция с Git
Эксперименты	MLflow	Удобный UI, регистрация моделей
Feature Store	Feast	Единый источник признаков
API	FastAPI	Высокая производительность, автодокументация
Оркестрация	Airflow	Мониторинг пайплайнов, перезапуск
Контейнеризация	Docker	Воспроизводимость, изоляция
Оркестрация контейнеров	Kubernetes	Масштабирование, отказоустойчивость
Мониторинг	Prometheus/Grafana	Сбор метрик, визуализация
CI/CD	GitHub Actions	Автоматизация деплоя
🔮 Пути улучшения
Масштабирование: Добавить горизонтальное масштабирование в K8s

A/B тестирование: Запуск нескольких версий моделей

Shadow mode: Тестирование новых моделей на реальном трафике

Автоматический откат: При падении метрик после деплоя

Бюджетирование: Контроль затрат на инфраструктуру

📝 Чек-лист выполнения
Лабораторная 1: Настройка репозитория

Лабораторная 2: DVC версионирование

Лабораторная 3: DVC пайплайн

Лабораторная 4: MLflow эксперименты

Лабораторная 5: Model Registry

Лабораторная 6: FastAPI + Docker

Лабораторная 7: Тесты + CI

Лабораторная 8: Airflow оркестрация

Лабораторная 9: Feast Feature Store

Лабораторная 10: Kubernetes деплой

Лабораторная 11: Prometheus + Grafana

Лабораторная 12: Детекция дрейфа

Лабораторная 13: CI/CD пайплайн

Лабораторная 14: Итоговая интеграция

🎥 Демо-ролик
(здесь будет ссылка на видео-демонстрацию)

