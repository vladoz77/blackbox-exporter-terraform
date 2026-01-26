# Ansible Role: monitoring

Ansible-роль для развёртывания полноценного стека мониторинга на базе **VictoriaMetrics**, **VMAlert**, **Alertmanager** и **Grafana** с использованием **Docker Compose**.

Роль предназначена для быстрого запуска self-hosted monitoring-стека и хорошо интегрируется с Traefik и Blackbox Exporter.

## Компоненты стека

| Компонент           | Назначение                                |
| ------------------- | ----------------------------------------- |
| **VictoriaMetrics** | Хранилище метрик и PromQL-совместимый API |
| **VMAlert**         | Обработка alert-правил                    |
| **Alertmanager**    | Маршрутизация и отправка алертов          |
| **Grafana**         | Визуализация метрик и дашборды            |

Каждый компонент может быть включён или отключён через variables.

## Возможности

* Развёртывание monitoring-стека через Docker Compose
* Health-check и ожидание готовности сервисов
* Автоматический provisioning Grafana:

  * datasources
  * dashboards
* Поддержка alert rules (VMAlert / Alertmanager)
* Поддержка дополнительных scrape-конфигураций
* Интеграция с Traefik (HTTPS + Host rules)
* Общая Docker-сеть для всего стека

## Структура роли

```text
monitoring/
├── defaults
│   └── main.yaml              # Переменные по умолчанию
├── files
│   ├── dashboards             # Grafana dashboards
│   └── rules                  # Alert rules
├── tasks
│   ├── main.yaml              # Оркестрация компонентов
│   ├── victoriametrics.yaml
│   ├── vmalert.yaml
│   ├── alertmanager.yaml
│   └── grafana.yaml
├── templates                  # docker-compose и config шаблоны
├── vars
│   └── main.yaml              # Пути и директории
├── requirements.yaml
└── README.md
```

## Требования

* Docker
* Docker Compose v2
* Ansible `community.docker`
* Traefik (опционально, для HTTPS)
* Доступ к 80/443 (если используется Traefik)

## Переменные роли

### Общие

| Переменная            | Описание                   | По умолчанию                      |
| --------------------- | -------------------------- | --------------------------------- |
| `docker_network_name` | Docker-сеть для monitoring | `monitoring_network`              |
| `work_dir`            | Рабочий каталог стека      | `/home/{{ username }}/monitoring` |

### VictoriaMetrics

| Переменная                      | Описание                 | По умолчанию    |
| ------------------------------- | ------------------------ | --------------- |
| `victoriametrics_enable`        | Включить VictoriaMetrics | `true`          |
| `victoriametrics_version`       | Версия                   | `v1.118.0`      |
| `victoriametrics_port`          | Порт                     | `8428`          |
| `victoriametrics_url`           | DNS-имя                  | `vm.home.local` |
| `scrape_interval`               | Интервал сбора           | `10s`           |
| `additional_scrape_configs_dir` | Доп. scrape jobs         | `jobs/`         |

### VMAlert

| Переменная        | Описание         | По умолчанию         |
| ----------------- | ---------------- | -------------------- |
| `vmalert_enable`  | Включить VMAlert | `true`               |
| `vmalert_version` | Версия           | `v1.118.0`           |
| `vmalert_port`    | Порт             | `8880`               |
| `vmalert_url`     | DNS-имя          | `vmalert.home.local` |

### Alertmanager

| Переменная             | Описание              | По умолчанию              |
| ---------------------- | --------------------- | ------------------------- |
| `alertmanager_enable`  | Включить Alertmanager | `true`                    |
| `alertmanager_version` | Версия                | `v0.28.0`                 |
| `alertmanager_port`    | Порт                  | `9093`                    |
| `alertmanager_url`     | DNS-имя               | `alertmanager.home.local` |

### Grafana

| Переменная        | Описание         | По умолчанию         |
| ----------------- | ---------------- | -------------------- |
| `grafana_enable`  | Включить Grafana | `true`               |
| `grafana_version` | Версия           | `11.5.0`             |
| `grafana_port`    | Порт             | `3000`               |
| `grafana_url`     | DNS-имя          | `grafana.home.local` |
| `grafana_data`    | Docker volume    | `grafana`            |

## Пример использования

```yaml
- hosts: monitoring
  become: true
  roles:
    - role: docker
    - role: monitoring
```

## Логика выполнения

1. Устанавливается **VictoriaMetrics**
2. Ожидание health-check
3. Устанавливается **Alertmanager**
4. Ожидание health-check
5. Устанавливается **VMAlert**
6. Устанавливается **Grafana**
7. Ожидание готовности Grafana

Каждый шаг можно отключить через `*_enable: false`.

## Grafana

* Datasource создаётся автоматически
* Дашборды загружаются из `files/dashboards`
* Provisioning через `file` provider
* Обновление каждые `30s`

## Alerts

* Правила хранятся в `files/rules`
* VMAlert читает правила из volume
* Alertmanager использует шаблон `alertmanager.yaml`

## Traefik

Все сервисы автоматически регистрируются в Traefik через labels:

* HTTPS
* Host-based routing
* Let's Encrypt

