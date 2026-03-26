# Ansible Role: monitoring

Роль разворачивает monitoring-стек в Docker Compose на базе VictoriaMetrics, VMAlert, Alertmanager и Grafana.

## Компоненты

| Компонент | Назначение |
| --- | --- |
| `VictoriaMetrics` | хранилище метрик и PromQL-compatible API |
| `VMAlert` | выполнение alert-правил |
| `Alertmanager` | маршрутизация и отправка алертов |
| `Grafana` | визуализация и dashboards |

Каждый компонент можно отключить через `*_enable`.

## Возможности

* раздельные compose-шаблоны для каждого компонента
* healthcheck перед установкой
* provisioning Grafana через шаблоны datasource и dashboard provider
* загрузка dashboard JSON из `files/dashboards`
* загрузка alert rules из `files/rules`
* поддержка дополнительных scrape jobs
* интеграция с Traefik через labels

## Структура

```text
monitoring/
├── defaults/
│   └── main.yaml
├── files/
│   ├── dashboards/
│   └── rules/
├── handlers/
│   └── main.yaml
├── tasks/
│   ├── alertmanager.yaml
│   ├── grafana.yaml
│   ├── main.yaml
│   ├── victoriametrics.yaml
│   └── vmalert.yaml
├── templates/
│   ├── alertmanager.yaml.j2
│   ├── alertmanager_compose.yaml.j2
│   ├── dashboards.yaml.j2
│   ├── datasources.yaml.j2
│   ├── grafana_compose.yaml.j2
│   ├── scrape.yaml.j2
│   ├── victoriametrics_compose.yaml.j2
│   └── vmalert_compose.yaml.j2
├── vars/
│   └── main.yaml
├── requirements.yaml
└── Readme.md
```

## Требования

* Docker
* Docker Compose v2
* collection `community.docker`
* Traefik опционально, если сервисы публикуются по HTTPS

## Основные переменные

### Общие

| Переменная | Описание | По умолчанию |
| --- | --- | --- |
| `docker_network_name` | Docker-сеть стека | `monitoring_network` |
| `work_dir` | Рабочий каталог роли | `/home/{{ username }}/monitoring` |

### VictoriaMetrics

| Переменная | По умолчанию |
| --- | --- |
| `victoriametrics_enable` | `true` |
| `victoriametrics_version` | `v1.118.0` |
| `victoriametrics_container_name` | `victoriametrics` |
| `victoriametrics_repo` | `victoriametrics/victoria-metrics` |
| `victoriametrics_port` | `8428` |
| `victoriametrics_url` | `vm.home.local` |
| `scrape_interval` | `10s` |
| `additional_scrape_configs_dir` | `{{ victoriametrics_dir }}/jobs` |
| `victoriametrics_data` | `vmstorage` |

### VMAlert

| Переменная | По умолчанию |
| --- | --- |
| `vmalert_enable` | `true` |
| `vmalert_container_name` | `vmalert` |
| `vmalert_repo` | `victoriametrics/vmalert` |
| `vmalert_version` | `v1.118.0` |
| `vmalert_port` | `8880` |
| `vmalert_url` | `vmalert.home.local` |
| `vmalert_rules_folder` | `{{vmalert_dir}}/rules` |

### Alertmanager

| Переменная | По умолчанию |
| --- | --- |
| `alertmanager_enable` | `true` |
| `alertmanager_container_name` | `alertmanager` |
| `alertmanager_repo` | `prom/alertmanager` |
| `alertmanager_version` | `v0.28.0` |
| `alertmanager_port` | `9093` |
| `alertmanager_url` | `alertmanager.home.local` |

### Grafana

| Переменная | По умолчанию |
| --- | --- |
| `grafana_enable` | `true` |
| `grafana_container_name` | `grafana` |
| `grafana_repo` | `grafana/grafana` |
| `grafana_version` | `11.5.0` |
| `grafana_port` | `3000` |
| `grafana_url` | `grafana.home.local` |
| `grafana_data` | `grafana` |

## Логика работы

`tasks/main.yaml` выполняет компоненты последовательно:

1. проверка healthcheck VictoriaMetrics и установка при необходимости
2. проверка healthcheck Alertmanager и установка при необходимости
3. проверка healthcheck VMAlert и установка при необходимости
4. проверка healthcheck Grafana и установка при необходимости

Если контейнер уже отвечает успешно, повторная установка соответствующего компонента пропускается.

## Пример

```yaml
- hosts: monitoring-server
  become: true
  roles:
    - role: docker
    - role: monitoring
```
