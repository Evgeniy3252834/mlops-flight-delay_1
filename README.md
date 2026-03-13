# MLOps Flight Delay Prediction Project

## 🚀 Полный пайплайн MLOps

### Архитектура проекта
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│ Данные │────▶│ DVC │────▶│ Предобработка │
│ (raw CSV) │ │ версионирование│ │ │
└─────────────────┘ └─────────────────┘ └─────────────────┘
│ │
▼ ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│ MLflow │◀────│ Обучение │◀────│ Feature Store │
│ Registry │ │ модели │ │ Feast │
└─────────────────┘ └─────────────────┘ └─────────────────┘
│ │ │
▼ ▼ ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│ FastAPI │ │ Airflow │ │ Prometheus │
│ REST │ │ оркестрация │ │ мониторинг │
└─────────────────┘ └─────────────────┘ └─────────────────┘
│ │ │
└───────────────────────┼───────────────────────┘
▼
┌─────────────────────┐
│ Kubernetes │
│ (Minikube) │
└─────────────────────┘
│
▼
┌─────────────────────┐
│ CI/CD │
│ (GitHub Actions) │
└─────────────────────┘

## 📋 Инструкция по установке

```bash
git clone https://github.com/Evgeniy3252834/mlops-flight-delay.git
cd mlops-flight-delay
conda create -n mlops python=3.10 -y
conda activate mlops
pip install -r requirements.txt```
##🎯 Функциональность
✅ Версионирование данных (DVC)

✅ Эксперименты и регистрация моделей (MLflow)

✅ Feature Store (Feast)

✅ REST API (FastAPI)

✅ Оркестрация пайплайнов (Airflow)

✅ Контейнеризация (Docker)

✅ Оркестрация контейнеров (Kubernetes/Minikube)

✅ Мониторинг (Prometheus/Grafana)

✅ Детекция дрейфа

✅ CI/CD (GitHub Actions)

📊 Пример запроса к API
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
📈 Метрики модели
Метрика	Значение
Accuracy	0.95
ROC-AUC	0.98
Precision	0.94
Recall	0.96
🛠 Технологии
https://img.shields.io/badge/Python-3.10-blue
https://img.shields.io/badge/FastAPI-0.104-green
https://img.shields.io/badge/Docker-24.0-blue
https://img.shields.io/badge/Kubernetes-1.28-blue
https://img.shields.io/badge/MLflow-2.8-orange
https://img.shields.io/badge/DVC-3.0-purple
