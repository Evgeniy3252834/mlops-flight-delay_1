#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Упрощенная детекция дрейфа без evidently
"""

import pandas as pd
import numpy as np
import json
import joblib
import logging
import os
import sys
import subprocess
from datetime import datetime
from sklearn.metrics import accuracy_score, roc_auc_score

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

THRESHOLDS = {
    'psi_threshold': 0.2,
    'performance_drift': 0.05
}

def calculate_psi(expected, actual, bins=10):
    """Population Stability Index"""
    expected = np.array(expected).flatten()
    actual = np.array(actual).flatten()
    
    min_val = min(expected.min(), actual.min())
    max_val = max(expected.max(), actual.max())
    
    bin_edges = np.linspace(min_val, max_val, bins + 1)
    
    expected_counts, _ = np.histogram(expected, bins=bin_edges)
    actual_counts, _ = np.histogram(actual, bins=bin_edges)
    
    expected_pct = expected_counts / len(expected)
    actual_pct = actual_counts / len(actual)
    
    expected_pct = np.clip(expected_pct, 0.001, 1)
    actual_pct = np.clip(actual_pct, 0.001, 1)
    
    psi = np.sum((actual_pct - expected_pct) * np.log(actual_pct / expected_pct))
    return psi

def check_drift():
    logger.info("="*60)
    logger.info("🚀 ПРОВЕРКА ДРЕЙФА")
    logger.info("="*60)
    
    # Загружаем данные
    reference_df = pd.read_csv('data/processed/processed.csv')
    
    current_path = 'data/processed/current_data.csv'
    if os.path.exists(current_path):
        current_df = pd.read_csv(current_path)
    else:
        logger.warning("Текущие данные не найдены, использую reference")
        current_df = reference_df.copy()
    
    # Загружаем модель
    model = joblib.load('models/model.joblib')
    
    # Выбираем числовые признаки для PSI
    numeric_cols = reference_df.select_dtypes(include=[np.number]).columns.tolist()
    if 'delay_flag' in numeric_cols:
        numeric_cols.remove('delay_flag')
    
    # Расчет PSI для каждого признака
    psi_results = {}
    for col in numeric_cols[:5]:  # первые 5 признаков
        psi = calculate_psi(reference_df[col], current_df[col])
        psi_results[col] = psi
        logger.info(f"📊 PSI для {col}: {psi:.4f}")
    
    # Оценка производительности
    feature_cols = [c for c in reference_df.columns if c != 'delay_flag']
    X_ref = reference_df[feature_cols]
    y_ref = reference_df['delay_flag']
    X_cur = current_df[feature_cols]
    y_cur = current_df['delay_flag']
    
    ref_pred = model.predict(X_ref)
    cur_pred = model.predict(X_cur)
    
    ref_acc = accuracy_score(y_ref, ref_pred)
    cur_acc = accuracy_score(y_cur, cur_pred)
    
    logger.info(f"\n📈 Производительность:")
    logger.info(f"   Reference accuracy: {ref_acc:.4f}")
    logger.info(f"   Current accuracy: {cur_acc:.4f}")
    logger.info(f"   Дрейф: {ref_acc - cur_acc:.4f}")
    
    # Решение о переобучении
    drift_detected = (ref_acc - cur_acc) > THRESHOLDS['performance_drift']
    
    if drift_detected:
        logger.warning("⚠️ ДРЕЙФ ОБНАРУЖЕН! Запуск переобучения...")
        
        result = subprocess.run(
            [sys.executable, 'src/train.py', '--model_type', 'random_forest'],
            capture_output=True,
            text=True
        )
        
        if result.returncode == 0:
            logger.info("✅ Переобучение успешно")
        else:
            logger.error(f"❌ Ошибка: {result.stderr}")
    else:
        logger.info("✅ Дрейф не обнаружен")
    
    # Сохраняем отчет
    report = {
        'timestamp': datetime.now().isoformat(),
        'psi': psi_results,
        'reference_accuracy': ref_acc,
        'current_accuracy': cur_acc,
        'drift_detected': drift_detected
    }
    
    with open('reports/drift_report_simple.json', 'w') as f:
        json.dump(report, f, indent=2)
    
    logger.info("✅ Отчет сохранен")
    return drift_detected

if __name__ == "__main__":
    check_drift()
