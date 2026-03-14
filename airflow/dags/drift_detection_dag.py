"""
DAG для обнаружения дрейфа и автоматического переобучения
"""

import json
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


def check_drift_result(**context):
    """Проверка результата дрейфа и запуск переобучения"""
    drift_report = Path("/opt/airflow/reports/drift_report.json")

    if drift_report.exists():
        with open(drift_report, "r") as f:
            results = json.load(f)

        drift_detected = results.get("retraining_triggered", False)

        if drift_detected:
            context["ti"].xcom_push(key="drift_detected", value=True)
            return "retrain"
        else:
            context["ti"].xcom_push(key="drift_detected", value=False)
            return "skip"

    return "skip"


with DAG(
    "drift_detection_pipeline",
    default_args=default_args,
    description="Детекция дрейфа и автоматическое переобучение",
    schedule_interval="@hourly",
    catchup=False,
    tags=["mlops", "drift"],
) as dag:

    start = DummyOperator(task_id="start")

    # Генерация тестовых данных с дрейфом (опционально)
    generate_drift = BashOperator(
        task_id="generate_drift",
        bash_command="cd /opt/airflow && python src/generate_drift.py --intensity 0.3",
        trigger_rule=TriggerRule.ALL_SUCCESS,
    )

    # Проверка дрейфа
    check_drift = BashOperator(
        task_id="check_drift",
        bash_command="cd /opt/airflow && python src/drift_check.py",
        trigger_rule=TriggerRule.ALL_SUCCESS,
    )

    # Проверка результата
    check_result = PythonOperator(
        task_id="check_result", python_callable=check_drift_result
    )

    # Переобучение (если обнаружен дрейф)
    retrain = BashOperator(
        task_id="retrain_model",
        bash_command="cd /opt/airflow && python src/train.py --model_type random_forest",
        trigger_rule=TriggerRule.ALL_SUCCESS,
    )

    # Регистрация новой модели
    register = BashOperator(
        task_id="register_model",
        bash_command="cd /opt/airflow && python src/evaluate.py --register --stage Staging",
        trigger_rule=TriggerRule.ALL_SUCCESS,
    )

    # Пропуск переобучения
    skip_retrain = DummyOperator(task_id="skip_retrain")

    end = DummyOperator(task_id="end")

    # Определяем ветвление
    start >> generate_drift >> check_drift >> check_result
    check_result >> [retrain, skip_retrain]
    retrain >> register >> end
    skip_retrain >> end
