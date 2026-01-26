# Terragrunt инфраструктура (Yandex Cloud)

Этот репозиторий содержит описание инфраструктуры в **Yandex Cloud**, управляемой с помощью **Terragrunt** поверх **Terraform**.
Проект поддерживает несколько окружений (`prod`, `stage`) и использует переиспользуемые Terraform-модули, хранящиеся в отдельном репозитории.

## Используемые технологии

* **Terraform**
* **Terragrunt**
* **Yandex Cloud**
* **S3 backend (Yandex Object Storage)**
* **Ansible (генерация inventory)**

## Структура репозитория

```text
.
├── prod
│   ├── blackbox        # Инстанс Blackbox Exporter
│   ├── inventory       # Генерация Ansible inventory
│   ├── monitoring      # Инстанс мониторинга (Prometheus, Grafana, Alertmanager)
│   └── vpc             # Сеть и подсеть
├── stage
│   ├── blackbox
│   ├── inventory
│   └── vpc
└── root.hcl            # Общая конфигурация Terragrunt
```

### Логика структуры

* **Каждое окружение** (`prod`, `stage`) изолировано
* **Каждый компонент** (VPC, instance, inventory) — отдельный Terragrunt-модуль
* Общие настройки вынесены в `root.hcl`
* Состояние Terraform хранится **централизованно в S3**
---

## Окружения

### `stage`

* Тестовое окружение
* Возможен запуск нескольких инстансов (`count`)
* Используется для проверки изменений

### `prod`

* Боёвое окружение
* Отдельные инстансы под конкретные роли
* Полный набор сервисов мониторинга

## Используемые Terraform-модули

Все модули подключаются из репозитория:

```
https://github.com/vladoz77/terraform-modules
```

Используемые модули:

| Модуль              | Назначение                  |
| ------------------- | --------------------------- |
| `yc-network`        | Создание VPC и подсети      |
| `yc-instance`       | ВМ в Yandex Cloud           |
| `ansible-inventory` | Генерация Ansible inventory |

## Зависимости между модулями

Terragrunt `dependency` используется для передачи данных между модулями:

* `instance` зависит от `vpc` (subnet_id)
* `inventory` зависит от `blackbox` и `monitoring` (public_ips)

Для команд `plan`, `init`, `validate` используются `mock_outputs`, чтобы:

* не поднимать реальные ресурсы
* избежать циклических зависимостей

## Remote State

Состояние Terraform хранится в **Yandex Object Storage**:

* backend: `s3`
* ключ формируется автоматически:

  ```text
  instances/<env>/<module>/blackbox.tfstate
  ```

Все настройки backend’а централизованы в `root.hcl`.

## Общая конфигурация (`root.hcl`)

В `root.hcl` описаны:

* backend Terraform
* provider Yandex Cloud
* общие `locals`
* общие `inputs` для всех модулей

### Переменные берутся из окружения

Перед работой необходимо экспортировать:

```bash
export TF_VAR_iam_token=***
export TF_VAR_cloud_id=***
export TF_VAR_folder_id=***
export TF_VAR_ssh_pub_key="ssh-ed25519 AAAA..."
export ACCESS_KEY=***
export SECRET_KEY=***
```

## Как работать с проектом

### Инициализация

```bash
terragrunt init
```

### План

```bash
terragrunt plan
```

### Применение

```bash
terragrunt apply
```

### Запуск всего окружения

Из каталога окружения:

```bash
cd prod
terragrunt run-all apply
```

## DNS

* DNS-записи создаются автоматически
* Используется зона: `home-local-zone`
* Записи описываются в `dns_records` каждого модуля

## Ansible inventory

Модуль `ansible-inventory`:

* собирает public IP инстансов
* генерирует inventory-файлы
* раскладывает их в:

  ```text
  ansible/inventories/<environment>
  ```



