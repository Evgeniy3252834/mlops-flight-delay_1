@echo off
cd C:\Users\Евгений\mlops-flight-delay
call conda activate mlops
python src/drift_check.py >> logs/drift.log 2>&1
