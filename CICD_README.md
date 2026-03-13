# CI/CD Pipeline

## Настройка GitHub Secrets

### 1. KUBE_CONFIG
```bash
./scripts/get-kubeconfig.sh
Структура пайплайна
test.yml - запуск тестов

deploy.yml - сборка и деплой
