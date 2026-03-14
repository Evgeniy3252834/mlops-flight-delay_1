#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Скрипт для обучения модели предсказания задержек рейсов
"""

import argparse
import json
import logging
from datetime import datetime
from pathlib import Path

import joblib
import mlflow
import mlflow.sklearn
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (accuracy_score, f1_score, precision_score,
                             recall_score, roc_auc_score)
from sklearn.model_selection import train_test_split

logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

Path("models").mkdir(exist_ok=True)
Path("reports").mkdir(exist_ok=True)


def load_data():
    """Загрузка и подготовка данных"""
    logger.info("Загрузка данных...")

    df = pd.read_csv("data/processed/processed.csv")
    logger.info(f"Загружено {len(df)} строк")

    try:
        with open("data/processed/features_info.json", "r") as f:
            features_info = json.load(f)
            logger.info(f"Всего признаков: {features_info['total_features']}")
    except Exception as e:
        logger.warning(f"Файл features_info.json не найден: {e}")

    target_col = "delay_flag"
    exclude_cols = [
        "delay_flag",
        "flight_date",
        "dep_time",
        "arr_time",
        "dep_delay",
        "arr_delay",
        "flight_id",
    ]

    feature_cols = [
        col
        for col in df.columns
        if col not in exclude_cols
        and col in df.columns
        and df[col].dtype in ["int64", "float64", "bool"]
    ]

    logger.info(f"Используемые признаки ({len(feature_cols)}):")
    logger.info(f"  {feature_cols}")

    X = df[feature_cols]
    y = df[target_col]

    if X.isnull().any().any():
        logger.warning("Есть пропущенные значения, заполняем средними")
        X = X.fillna(X.mean())

    logger.info(f"Размерность X: {X.shape}")
    logger.info(f"Размерность y: {y.shape}")

    return X, y, feature_cols


def train_random_forest(X_train, y_train, X_test, y_test, params):
    """Обучение Random Forest"""
    logger.info("Обучение Random Forest...")

    with mlflow.start_run(nested=True):
        mlflow.log_params(
            {
                "model_type": "random_forest",
                "n_estimators": params.get("n_estimators", 100),
                "max_depth": params.get("max_depth", 10),
                "min_samples_split": params.get("min_samples_split", 2),
                "min_samples_leaf": params.get("min_samples_leaf", 1),
            }
        )

        model = RandomForestClassifier(
            n_estimators=params.get("n_estimators", 100),
            max_depth=params.get("max_depth", 10),
            min_samples_split=params.get("min_samples_split", 2),
            min_samples_leaf=params.get("min_samples_leaf", 1),
            random_state=42,
            n_jobs=-1,
        )

        model.fit(X_train, y_train)
        y_pred = model.predict(X_test)
        y_pred_proba = model.predict_proba(X_test)[:, 1]

        metrics = {
            "accuracy": accuracy_score(y_test, y_pred),
            "roc_auc": roc_auc_score(y_test, y_pred_proba),
            "precision": precision_score(y_test, y_pred),
            "recall": recall_score(y_test, y_pred),
            "f1_score": f1_score(y_test, y_pred),
        }

        mlflow.log_metrics(metrics)

        feature_importance = pd.DataFrame(
            {"feature": X_train.columns, "importance": model.feature_importances_}
        ).sort_values("importance", ascending=False)

        feature_importance.to_csv("reports/feature_importance_rf.csv", index=False)
        mlflow.log_artifact("reports/feature_importance_rf.csv")

        return model, metrics


def train_logistic_regression(X_train, y_train, X_test, y_test, params):
    """Обучение Logistic Regression"""
    logger.info("Обучение Logistic Regression...")

    with mlflow.start_run(nested=True):
        mlflow.log_params(
            {
                "model_type": "logistic_regression",
                "C": params.get("C", 1.0),
                "max_iter": params.get("max_iter", 1000),
                "solver": params.get("solver", "lbfgs"),
            }
        )

        model = LogisticRegression(
            C=params.get("C", 1.0),
            max_iter=params.get("max_iter", 1000),
            solver=params.get("solver", "lbfgs"),
            random_state=42,
            n_jobs=-1,
        )

        model.fit(X_train, y_train)
        y_pred = model.predict(X_test)
        y_pred_proba = model.predict_proba(X_test)[:, 1]

        metrics = {
            "accuracy": accuracy_score(y_test, y_pred),
            "roc_auc": roc_auc_score(y_test, y_pred_proba),
            "precision": precision_score(y_test, y_pred),
            "recall": recall_score(y_test, y_pred),
            "f1_score": f1_score(y_test, y_pred),
        }

        mlflow.log_metrics(metrics)

        coefficients = pd.DataFrame(
            {"feature": X_train.columns, "coefficient": model.coef_[0]}
        ).sort_values("coefficient", ascending=False)

        coefficients.to_csv("reports/coefficients_lr.csv", index=False)
        mlflow.log_artifact("reports/coefficients_lr.csv")

        return model, metrics


def main():
    """Основная функция"""
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--model_type",
        type=str,
        default="random_forest",
        choices=["random_forest", "logistic_regression", "both"],
    )
    parser.add_argument("--n_estimators", type=int, default=100)
    parser.add_argument("--max_depth", type=int, default=10)
    parser.add_argument("--C", type=float, default=1.0)
    parser.add_argument("--experiment_name", type=str, default="flight_delay")
    args = parser.parse_args()

    logger.info("=" * 60)
    logger.info("НАЧАЛО ОБУЧЕНИЯ МОДЕЛИ")
    logger.info("=" * 60)

    mlflow.set_experiment(args.experiment_name)
    X, y, feature_cols = load_data()

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )

    logger.info(f"Размер обучающей выборки: {len(X_train)}")
    logger.info(f"Размер тестовой выборки: {len(X_test)}")

    run_name = f"run_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
    with mlflow.start_run(run_name=run_name):

        mlflow.log_params(
            {
                "test_size": 0.2,
                "random_state": 42,
                "feature_count": len(feature_cols),
                "train_size": len(X_train),
            }
        )

        try:
            mlflow.log_artifact("data/processed/features_info.json")
        except Exception as e:
            logger.warning(f"Не удалось залогировать features_info.json: {e}")

        models = {}
        metrics = {}

        if args.model_type in ["random_forest", "both"]:
            rf_params = {"n_estimators": args.n_estimators, "max_depth": args.max_depth}
            model_rf, metrics_rf = train_random_forest(
                X_train, y_train, X_test, y_test, rf_params
            )
            models["random_forest"] = model_rf
            metrics["random_forest"] = metrics_rf

        if args.model_type in ["logistic_regression", "both"]:
            lr_params = {"C": args.C}
            model_lr, metrics_lr = train_logistic_regression(
                X_train, y_train, X_test, y_test, lr_params
            )
            models["logistic_regression"] = model_lr
            metrics["logistic_regression"] = metrics_lr

        if models:
            model = list(models.values())[0]
            model_path = "models/model.joblib"
            joblib.dump(model, model_path)
            mlflow.log_artifact(model_path)

            mlflow.sklearn.log_model(
                model, "model", registered_model_name="flight_delay_model"
            )

            with open("reports/metrics.json", "w") as f:
                json.dump(metrics, f, indent=2)
            mlflow.log_artifact("reports/metrics.json")

            with open("models/features.txt", "w") as f:
                f.write("\n".join(feature_cols))
            mlflow.log_artifact("models/features.txt")

            logger.info(f"Run ID: {mlflow.active_run().info.run_id}")
            logger.info(f"Модель сохранена: {model_path}")

    logger.info("\n" + "=" * 60)
    logger.info("ОБУЧЕНИЕ ЗАВЕРШЕНО")
    logger.info("=" * 60)


if __name__ == "__main__":
    main()
