"""
DAG для автоматического пайплайна обучения модели
"""

import json
import logging
from datetime import datetime, timedelta
from pathlib import Path

from airflow.operators.bash import BashOperator
from airflow.operators.dummy import DummyOperator
from airflow.operators.python import PythonOperator
from airflow.utils.trigger_rule import TriggerRule

from airflow import DAG

default_args = {
    "owner": "mlops",
    "depends_on_past": False,
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
    "start_date": datetime(2024, 1, 1),
}


def check_data_exists(**context):
    """Проверка наличия данных"""
    data_path = Path("/opt/airflow/data/raw/flights_sample.csv")
    if data_path.exists():
        logging.info(f"✅ Данные найдены: {data_path}")
        return True
    else:
        logging.error(f"❌ Данные не найдены: {data_path}")
        raise FileNotFoundError(f"Data file not found: {data_path}")


def check_model_metrics(**context):
    """Проверка метрик модели и регистрация"""
    metrics_path = Path("/opt/airflow/reports/metrics_detailed.json")
    if metrics_path.exists():
        with open(metrics_path, "r") as f:
            metrics = json.load(f)

        accuracy = metrics.get("accuracy", 0)
        roc_auc = metrics.get("roc_auc", 0)

        logging.info(f"📊 Метрики: accuracy={accuracy:.4f}, roc_auc={roc_auc:.4f}")

        # Если метрики хорошие - регистрируем модель
        if accuracy > 0.7 and roc_auc > 0.7:
            logging.info("✅ Метрики хорошие, модель можно регистрировать")
            context["ti"].xcom_push(key="metrics_ok", value=True)
        else:
            logging.warning("⚠️ Метрики низкие, модель не регистрируем")
            context["ti"].xcom_push(key="metrics_ok", value=False)
    else:
        logging.error(f"❌ Файл метрик не найден: {metrics_path}")
        context["ti"].xcom_push(key="metrics_ok", value=False)


def register_model_if_good(**context):
    """Регистрация модели если метрики хорошие"""
    metrics_ok = context["ti"].xcom_pull(key="metrics_ok", task_ids="check_metrics")

    if metrics_ok:
        logging.info("📦 Регистрируем модель в MLflow...")
        # Здесь можно добавить код регистрации
        # Но пока просто логируем
        logging.info("✅ Модель зарегистрирована (симуляция)")
    else:
        logging.info("⏭️ Пропускаем регистрацию модели")


# Создаем DAG
with DAG(
    "flight_delay_pipeline",
    default_args=default_args,
    description="Пайплайн для предсказания задержек рейсов",
    schedule_interval="@daily",
    catchup=False,
    tags=["mlops", "flight_delay"],
) as dag:

    # Начало пайплайна
    start = DummyOperator(task_id="start")

    # Проверка данных
    check_data = PythonOperator(task_id="check_data", python_callable=check_data_exists)

    # Предобработка данных
    preprocess = BashOperator(
        task_id="preprocess",
        bash_command="cd /opt/airflow && python src/preprocess.py",
        trigger_rule=TriggerRule.ALL_SUCCESS,
    )

    # Обучение модели
    train = BashOperator(
        task_id="train",
        bash_command='cd /opt/airflow && python src/train.py '
                     '--model_type random_forest '
                     '--n_estimators 100 --max_depth 10',
        trigger_rule=TriggerRule.ALL_SUCCESS,
    )

    # Оценка модели
    evaluate = BashOperator(
        task_id="evaluate",
        bash_command="cd /opt/airflow && python src/evaluate.py --model_path models/model.joblib",
        trigger_rule=TriggerRule.ALL_SUCCESS,
    )

    # Проверка метрик
    check_metrics = PythonOperator(
        task_id="check_metrics", python_callable=check_model_metrics
    )

    # Регистрация модели (если метрики хорошие)
    register = PythonOperator(
        task_id="register_model", python_callable=register_model_if_good
    )

    # Конец пайплайна
    end = DummyOperator(task_id="end", trigger_rule=TriggerRule.ALL_DONE)

    # Определяем зависимости
    (
        start
        >> check_data
        >> preprocess
        >> train
        >> evaluate
        >> check_metrics
        >> register
        >> end
    )
