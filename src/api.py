#!/usr/bin/env python
# -*- coding: utf-8 -*-

from fastapi import FastAPI, HTTPException
from fastapi.responses import Response
from pydantic import BaseModel, validator
import pandas as pd
import joblib
import logging
import time
from prometheus_client import Counter, Histogram, generate_latest

# Настройка логирования
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Создаем приложение
app = FastAPI(title="Flight Delay Prediction API with Monitoring")

# Метрики Prometheus
REQUEST_COUNT = Counter('http_requests_total', 'Total HTTP requests', ['method', 'endpoint', 'status'])
REQUEST_LATENCY = Histogram('http_request_duration_seconds', 'HTTP request latency', ['method', 'endpoint'])
PREDICTION_COUNT = Counter('predictions_total', 'Total predictions made', ['prediction_class'])
PREDICTION_PROBABILITY = Histogram('prediction_probability', 'Distribution of prediction probabilities', buckets=[0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0])

# Загружаем модель
model = joblib.load('models/model.joblib')
model_features = model.feature_names_in_.tolist()
logger.info(f"✅ Модель загружена, ожидает признаки: {model_features[:5]}...")

# Pydantic модели
class FlightFeatures(BaseModel):
    carrier: str
    origin: str
    dest: str
    dep_time: int
    distance: int
    flight_date: str

    @validator('carrier')
    def validate_carrier(cls, v):
        valid_carriers = ['AA', 'DL', 'UA', 'WN', 'B6']
        if v not in valid_carriers:
            raise ValueError(f'carrier must be one of {valid_carriers}')
        return v

class PredictionResponse(BaseModel):
    delay_probability: float
    prediction: int

# Middleware для сбора метрик
@app.middleware("http")
async def metrics_middleware(request, call_next):
    method = request.method
    endpoint = request.url.path

    start_time = time.time()
    response = await call_next(request)
    duration = time.time() - start_time

    REQUEST_COUNT.labels(method=method, endpoint=endpoint, status=response.status_code).inc()
    REQUEST_LATENCY.labels(method=method, endpoint=endpoint).observe(duration)

    return response

@app.get("/")
async def root():
    return {"message": "Flight Delay Prediction API with Monitoring", "version": "1.0.0"}

@app.get("/health")
async def health():
    return {"status": "ok", "model_loaded": True}

@app.get("/metrics")
async def metrics():
    """Endpoint для Prometheus"""
    return Response(content=generate_latest().decode('utf-8'), media_type="text/plain")

@app.post("/predict", response_model=PredictionResponse)
async def predict(features: FlightFeatures):
    try:
        df = create_features(features)
        proba = model.predict_proba(df)[0, 1]
        pred = int(proba > 0.5)

        PREDICTION_COUNT.labels(prediction_class=str(pred)).inc()
        PREDICTION_PROBABILITY.observe(proba)

        return PredictionResponse(delay_probability=float(proba), prediction=pred)
    except Exception as e:
        logger.error(f"Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/info")
async def info():
    return {"features": model_features[:10], "features_count": len(model_features)}

def create_features(req: FlightFeatures) -> pd.DataFrame:
    data = {col: [0] for col in model_features}

    flight_date = pd.to_datetime(req.flight_date)
    data['day_of_week'] = [flight_date.dayofweek]
    data['is_weekend'] = [1 if flight_date.dayofweek >= 5 else 0]
    data['dep_hour'] = [req.dep_time // 100]
    data['distance'] = [req.distance]

    carriers = ['AA', 'DL', 'UA', 'WN', 'B6']
    for c in carriers:
        data[f'carrier_{c}'] = [1 if req.carrier == c else 0]

    df = pd.DataFrame(data)
    return df[model_features]

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)
