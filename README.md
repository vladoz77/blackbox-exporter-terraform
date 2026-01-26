# Infrastructure as Code: Terraform + Ansible

Этот репозиторий содержит полный цикл управления инфраструктурой и сервисами:

* **Terraform + Terragrunt** — создание инфраструктуры (VPC, VM, inventory)
* **Ansible** — конфигурация серверов и запуск сервисов
* Поддержка **stage / prod** окружений
* Мониторинг, Blackbox Exporter, Traefik, Docker

Проект следует принципам **Infrastructure as Code** и **Immutable-ish infrastructure**:

* Terraform отвечает за *что создать*
* Ansible — *как это настроить*

## Общая архитектура

```text
Terraform (Terragrunt)
        ↓
  VM / Network / Inventory
        ↓
     Ansible
        ↓
 Docker / Monitoring / Traefik / Blackbox
```
## Структура репозитория

```text
.
├── terraform/          # Инфраструктура (Terragrunt)
├── ansible/            # Конфигурация и сервисы
└── README.md           # Этот файл
```

## Окружения

Поддерживаются отдельные окружения:

* `stage` — тестовое / sandbox
* `prod` — production

Разделение реализовано **и в Terraform, и в Ansible**.

## Terraform / Terragrunt

Каталог: `terraform/`

```text
terraform/
├── root.hcl            # Общие настройки Terragrunt
├── stage/
│   ├── vpc/
│   ├── inventory/
│   └── blackbox/
└── prod/
    ├── vpc/
    ├── inventory/
    ├── monitoring/
    └── blackbox/
```

### Что делает Terraform

* Создаёт VPC и сети
* Создаёт VM для:

  * monitoring
  * blackbox
* Формирует inventory (используется Ansible)
* Управляет state через S3 (Terragrunt)

Подробнее см. `terraform/Readme.md`

## Ansible

Каталог: `ansible/`

```text
ansible/
├── inventories/        # Inventory по окружениям
├── roles/              # Роли
├── blackbox-prod.yaml  # Playbook prod
├── blackbox-stage.yaml # Playbook stage
└── Readme.md
```

## Ansible Roles

### `common`

Базовая подготовка сервера:

* системные пакеты
* базовые настройки

### `docker`

* Установка Docker
* Docker Compose v2
* Создание Docker network

### `traefik`

* Traefik v3 (Docker)
* HTTPS (Let’s Encrypt)
* staging / prod ACME
* Синхронизация `acme.json` с S3
* (опционально) Dashboard

### `monitoring`

Полноценный monitoring stack:

* VictoriaMetrics
* Alertmanager
* vmalert
* Grafana
* Dashboards и rules

### `blackbox-exporter`

* Blackbox Exporter в Docker
* Генерация scrape-конфигурации
* Интеграция с monitoring

## Playbooks

### Production

```yaml
blackbox-prod.yaml
```

Логика:

1. Все сервера:

   * `common`
   * `docker`
2. Monitoring сервер:

   * `monitoring`
   * `traefik`
3. Blackbox сервер:

   * `blackbox-exporter`
   * `traefik`

### Stage

```yaml
blackbox-stage.yaml
```

Stage-окружение совмещает роли:

* monitoring
* blackbox
* traefik
  на одном сервере.

---

##  Как пользоваться

### Создать инфраструктуру

```bash
cd terraform/prod/
terragrunt run --all init
terragrunt run --all apply
```

---

### Применить Ansible

```bash
cd ansible
ansible-playbook -i inventories/prod/inventory.ini blackbox-prod.yaml
```

Для stage:

```bash
ansible-playbook -i inventories/stage/inventory.ini blackbox-stage.yaml
```

## Безопасность и best practices

* HTTPS везде через Traefik
* ACME сертификаты:

  * staging для тестов
  * production для prod
* `acme.json` хранится в S3
* Docker-сервисы не публикуются без `traefik.enable=true`
* Разделение окружений на уровне каталогов

