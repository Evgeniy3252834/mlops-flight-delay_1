# Flight Delay Prediction API

## Запуск локально
```bash
python src/api.py
## Запуск в Docker
bash
# Сборка образа
docker build -t flight-delay-api:lab6 .

## Запуск контейнера
docker run -p 8080:8080 flight-delay-api:lab6
#Примеры запросов
##Проверка здоровья
bash
curl http://localhost:8080/health
## Предсказание
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
Информация о модели
bash
curl http://localhost:8080/info
