"""
Фикстуры для тестов
"""

import sys
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

# Добавляем путь к src
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from api import app


@pytest.fixture
def client():
    """Тестовый клиент FastAPI"""
    with TestClient(app) as test_client:
        yield test_client


@pytest.fixture
def sample_flight():
    """Пример корректных данных для теста"""
    return {
        "carrier": "AA",
        "origin": "JFK",
        "dest": "LAX",
        "dep_time": 930,
        "distance": 2475,
        "flight_date": "2023-06-15",
    }


@pytest.fixture
def invalid_flight():
    """Некорректные данные для теста"""
    return {
        "carrier": "XX",  # Несуществующая авиакомпания
        "origin": "XXX",  # Несуществующий аэропорт
        "dest": "LAX",
        "dep_time": 2500,  # Некорректное время (>2359)
        "distance": -100,  # Отрицательное расстояние
        "flight_date": "2023-06-15",
    }
