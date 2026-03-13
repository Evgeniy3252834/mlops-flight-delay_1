FROM python:3.10-slim

WORKDIR /app

# Устанавливаем зависимости
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Копируем код и модель
COPY src/ ./src/
COPY models/ ./models/

# Создаем пользователя для безопасности
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

# Экспортируем порт
EXPOSE 8080

# Запускаем API
CMD ["uvicorn", "src.api:app", "--host", "0.0.0.0", "--port", "8080"]
