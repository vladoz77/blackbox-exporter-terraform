# Ansible

Этот каталог содержит Ansible-playbooks и роли для конфигурации серверов, развертывания сервисов и мониторинга поверх инфраструктуры, созданной Terraform.

Ansible отвечает за:

* установку базового ПО
* Docker и Docker-сервисов
* Traefik (reverse-proxy + TLS)
* Monitoring stack
* Blackbox Exporter

Поддерживаются отдельные окружения **stage** и **prod**.

---

## Структура каталога

```text
ansible/
├── blackbox-prod.yaml        # Playbook для production
├── blackbox-stage.yaml       # Playbook для stage
├── inventories/              # Inventory по окружениям
│   ├── prod/
│   │   ├── inventory.ini
│   │   └── group_vars/
│   │       ├── blackbox-server.yaml
│   │       └── monitoring-server.yaml
│   └── stage/
│       └── group_vars/
│           └── monitoring-blackbox-server.yaml
├── roles/                    # Ansible roles
└── Readme.md                 # Этот файл
```

---

## Окружения

### Production (`prod`)

* Monitoring и Blackbox разнесены по разным серверам
* Отдельные группы:

  * `monitoring-server`
  * `blackbox-server`

### Stage (`stage`)

* Monitoring + Blackbox + Traefik запускаются **на одном сервере**
* Используется группа:

  * `monitoring-blackbox-server`

## Playbooks

### `blackbox-prod.yaml`

Используется для **production-окружения**.

Логика выполнения:

1. **Все серверы**

   * `common`
   * `docker`

2. **Monitoring сервер**

   * `monitoring`
   * `traefik`

3. **Blackbox сервер**

   * `blackbox-exporter`
   * `traefik`

Запуск:

```bash
ansible-playbook -i inventories/prod/inventory.ini blackbox-prod.yaml
```

### `blackbox-stage.yaml`

Используется для **stage / test** окружения.

Все сервисы разворачиваются на одном сервере:

* `common`
* `docker`
* `monitoring`
* `blackbox-exporter`
* `traefik`

Запуск:

```bash
ansible-playbook -i inventories/stage blackbox-stage.yaml
```

## Roles

### `common`

Базовая подготовка сервера:

* системные пакеты
* общие настройки ОС

### `docker`

* Установка Docker (Ubuntu / RHEL)
* Docker Compose v2
* Добавление пользователя в группу `docker`
* Создание Docker network

### `traefik`

* Traefik v3 в Docker
* HTTPS через Let’s Encrypt
* staging / production ACME
* Синхронизация `acme.json` с S3
* (опционально) Dashboard с basic-auth

### `monitoring`

Полный monitoring stack:

* VictoriaMetrics
* Alertmanager
* vmalert
* Grafana
* Dashboards и alert rules

### `blackbox-exporter`

* Blackbox Exporter в Docker
* HTTP/HTTPS probes
* Генерация scrape-конфига
* Интеграция с monitoring
* (опционально) basic-auth через Traefik

## Inventory и group_vars

Все переменные окружений хранятся в `group_vars`.

Примеры:

* домены
* credentials
* S3 / ACME настройки
* monitoring endpoints

Это позволяет:

* не хардкодить значения в ролях
* переиспользовать роли между окружениями

## Best practices

* Роли **идемпотентны**
* Docker-сервисы публикуются только через Traefik
* TLS сертификаты сохраняются в S3
* Stage и prod изолированы логически
* Ansible **не создаёт инфраструктуру** (это делает Terraform)

## Типичный workflow

1. Terraform создаёт инфраструктуру
2. Формируется inventory
3. Ansible настраивает серверы
4. Traefik поднимает HTTPS
5. Monitoring начинает собирать метрики

