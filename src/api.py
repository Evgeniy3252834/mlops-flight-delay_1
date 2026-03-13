#!/usr/bin/env python
# -*- coding: utf-8 -*-

import logging

import joblib
import pandas as pd
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, validator

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Flight Delay Prediction API")

# Загружаем модель
model = joblib.load("models/model.joblib")
model_features = model.feature_names_in_.tolist()
logger.info(f"✅ Модель загружена, ожидает признаки: {model_features[:5]}...")


class FlightFeatures(BaseModel):
    carrier: str
    origin: str
    dest: str
    dep_time: int
    distance: int
    flight_date: str

    @validator("carrier")
    def validate_carrier(cls, v):
        valid_carriers = ["AA", "DL", "UA", "WN", "B6"]
        if v not in valid_carriers:
            raise ValueError(f"carrier must be one of {valid_carriers}")
        return v

    @validator("origin")
    def validate_origin(cls, v):
        valid_airports = ["JFK", "LAX", "ORD", "DFW", "DEN", "ATL", "SFO"]
        if v not in valid_airports:
            raise ValueError(f"origin must be one of {valid_airports}")
        return v

    @validator("dest")
    def validate_dest(cls, v):
        valid_airports = ["JFK", "LAX", "ORD", "DFW", "DEN", "ATL", "SFO"]
        if v not in valid_airports:
            raise ValueError(f"dest must be one of {valid_airports}")
        return v

    @validator("dep_time")
    def validate_dep_time(cls, v):
        if v < 0 or v > 2359:
            raise ValueError("dep_time must be between 0 and 2359")
        if v % 100 >= 60:
            raise ValueError("minutes must be between 0 and 59")
        return v

    @validator("distance")
    def validate_distance(cls, v):
        if v <= 0:
            raise ValueError("distance must be positive")
        if v > 10000:
            raise ValueError("distance too large")
        return v


class PredictionResponse(BaseModel):
    delay_probability: float
    prediction: int


@app.get("/")
async def root():
    """Корневой endpoint"""
    return {
        "message": "Flight Delay Prediction API",
        "version": "1.0.0",
        "endpoints": ["/health", "/predict", "/info"],
    }


@app.get("/health")
async def health():
    """Проверка здоровья"""
    return {"status": "ok", "model_loaded": True}


@app.post("/predict", response_model=PredictionResponse)
async def predict(features: FlightFeatures):
    """Предсказание задержки"""
    try:
        # Валидация уже прошла через Pydantic
        df = create_features(features)
        proba = model.predict_proba(df)[0, 1]
        pred = int(proba > 0.5)

        return PredictionResponse(delay_probability=float(proba), prediction=pred)
    except ValueError as e:
        # Ошибки валидации
        raise HTTPException(status_code=422, detail=str(e))
    except Exception as e:
        logger.error(f"Ошибка: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/info")
async def info():
    """Информация о модели"""
    return {"features": model_features[:10], "features_count": len(model_features)}


def create_features(req: FlightFeatures) -> pd.DataFrame:
    """Создание признаков"""

    # База
    data = {col: [0] for col in model_features}

    # Основные признаки
    flight_date = pd.to_datetime(req.flight_date)
    data["day_of_week"] = [flight_date.dayofweek]
    data["is_weekend"] = [1 if flight_date.dayofweek >= 5 else 0]
    data["month"] = [flight_date.month]
    data["day_of_month"] = [flight_date.day]
    data["dep_hour"] = [req.dep_time // 100]
    data["dep_minute"] = [req.dep_time % 100]
    data["distance"] = [req.distance]
    data["distance_km"] = [req.distance * 1.60934]

    # One-hot encoding
    carriers = ["AA", "DL", "UA", "WN", "B6"]
    for c in carriers:
        data[f"carrier_{c}"] = [1 if req.carrier == c else 0]

    origins = ["JFK", "LAX", "ORD", "DFW", "DEN"]
    for o in origins:
        data[f"origin_{o}"] = [1 if req.origin == o else 0]

    dests = ["JFK", "LAX", "ORD", "DFW", "DEN"]
    for d in dests:
        data[f"dest_{d}"] = [1 if req.dest == d else 0]

    # Временные категории
    hour = req.dep_time // 100
    buckets = ["night", "morning", "afternoon", "evening"]
    if hour < 6:
        bucket = "night"
    elif hour < 12:
        bucket = "morning"
    elif hour < 18:
        bucket = "afternoon"
    else:
        bucket = "evening"

    for b in buckets:
        data[f"dep_time_bucket_{b}"] = [1 if bucket == b else 0]

    # Создаем DataFrame в правильном порядке
    df = pd.DataFrame(data)
    df = df[model_features]

    logger.info(f"Создано признаков: {df.shape[1]}")
    return df


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8080)
