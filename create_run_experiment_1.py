import mlflow
import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score
import warnings
warnings.filterwarnings('ignore')

# Настройка MLflow
mlflow.set_tracking_uri("sqlite:///mlflow.db")
print(f"Tracking URI: {mlflow.get_tracking_uri()}")

# Используем эксперимент ID=1
experiment_id = "1"
print(f"Используем эксперимент ID: {experiment_id}")

# Загружаем данные
print("\nЗагрузка данных...")
df = pd.read_csv("data/processed/processed.csv")
print(f"Загружено {len(df)} строк")

# Подготовка признаков (только числовые)
feature_cols = []
for col in df.columns:
    if col not in ['delay_flag', 'flight_date', 'dep_time', 'arr_time', 'dep_delay', 'arr_delay']:
        if df[col].dtype in ['int64', 'float64']:
            feature_cols.append(col)

X = df[feature_cols]
y = df['delay_flag']

print(f"Признаки: {feature_cols}")
print(f"Размер X: {X.shape}")

# Разделение
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# Создаем запуск в эксперименте ID=1
print("\nСоздание запуска в эксперименте ID=1...")

with mlflow.start_run(experiment_id=experiment_id, run_name="my_first_run"):
    # Параметры
    mlflow.log_param("model_type", "RandomForest")
    mlflow.log_param("n_estimators", 100)
    mlflow.log_param("max_depth", 10)
    mlflow.log_param("features", str(feature_cols))
    
    # Обучаем модель
    model = RandomForestClassifier(n_estimators=100, max_depth=10, random_state=42)
    model.fit(X_train, y_train)
    
    # Метрики
    y_pred = model.predict(X_test)
    accuracy = accuracy_score(y_test, y_pred)
    
    mlflow.log_metric("accuracy", accuracy)
    mlflow.log_metric("rows_count", len(df))
    
    # Логируем модель
    mlflow.sklearn.log_model(model, "model")
    
    run_id = mlflow.active_run().info.run_id
    print(f"\n✅ Запуск создан!")
    print(f"   Run ID: {run_id}")
    print(f"   Accuracy: {accuracy:.4f}")
    print(f"   Эксперимент ID: {experiment_id}")

print("\n✅ Готово! Теперь обновите страницу в браузере.")
