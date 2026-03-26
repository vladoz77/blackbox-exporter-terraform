# Ansible

Каталог содержит playbook'и, inventory и роли для настройки серверов после Terraform.

Ansible в этом проекте отвечает за:

* базовую подготовку хостов
* установку Docker
* развёртывание monitoring-стека
* запуск Blackbox Exporter
* настройку Traefik
* установку Grafana Alloy

## Структура каталога

```text
ansible/
├── ansible.cfg
├── blackbox-prod.yaml
├── blackbox-stage.yaml
├── inventories/
│   ├── prod/
│   │   ├── inventory.ini
│   │   └── group_vars/
│   │       ├── blackbox-server.yaml
│   │       └── monitoring-server.yaml
│   └── stage/
│       └── group_vars/
│           └── monitoring-blackbox-server.yaml
├── roles/
│   ├── blackbox-exporter/
│   ├── common/
│   ├── docker/
│   ├── grafana-alloy/
│   ├── monitoring/
│   └── traefik/
└── Readme.md
```

## Окружения

### `prod`

* группа `monitoring-server` для monitoring + traefik
* группа `blackbox-server` для blackbox + traefik
* роль `grafana-alloy` применяется ко всем хостам

### `stage`

* используется группа `monitoring-blackbox-server`
* роли `monitoring`, `blackbox-exporter`, `grafana-alloy` и `traefik` запускаются на одном сервере

## Playbook'и

### `blackbox-prod.yaml`

```text
all hosts            -> common, docker, grafana-alloy
monitoring-server    -> monitoring, traefik
blackbox-server      -> blackbox-exporter, traefik
```

Запуск:

```bash
ansible-playbook -i inventories/prod/inventory.ini blackbox-prod.yaml
```

### `blackbox-stage.yaml`

```text
monitoring-blackbox-server -> common, docker, monitoring, grafana-alloy, blackbox-exporter, traefik
```

Запуск:

```bash
ansible-playbook -i inventories/stage blackbox-stage.yaml
```

## Роли

### `common`

* hostname
* timezone
* базовые пакеты

### `docker`

* установка Docker Engine
* Docker Compose plugin
* подготовка docker network

### `monitoring`

* VictoriaMetrics
* VMAlert
* Alertmanager
* Grafana

### `grafana-alloy`

* установка бинарника Alloy
* systemd unit
* конфиг для remote_write и отправки логов

### `blackbox-exporter`

* контейнер Blackbox Exporter
* scrape config для monitoring
* reload VictoriaMetrics после обновления scrape-конфига

### `traefik`

* reverse proxy в Docker
* Let's Encrypt
* синхронизация `acme.json` с S3-совместимым хранилищем

## Inventory

Inventory-файлы и `group_vars` генерируются Terraform-модулем `ansible-inventory` в каталог `ansible/inventories`.

Вручную здесь обычно редактируются только:

* значения переменных окружения
* секреты и домены
* настройки ролей в `group_vars`
