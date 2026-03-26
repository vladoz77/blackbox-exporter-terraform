# Ansible Role: blackbox-exporter

Роль запускает Prometheus Blackbox Exporter в Docker и генерирует scrape-конфиг для monitoring-стека.

## Возможности

* Docker Compose шаблон для контейнера
* поддержка TLS и Basic Auth через Traefik labels
* генерация scrape-конфига
* копирование scrape-конфига на monitoring-хост
* reload VictoriaMetrics через handler
* идемпотентный пропуск установки, если контейнер уже работает

## Структура

```text
blackbox-exporter/
├── defaults/
│   └── main.yaml
├── files/
│   └── blackbox.yaml
├── handlers/
│   └── main.yaml
├── tasks/
│   ├── generate-password-hash.yaml
│   ├── install.yaml
│   └── main.yaml
├── templates/
│   ├── blackbox-scrape-config.yaml.j2
│   └── docker-compose.yaml.j2
└── README.md
```

## Требования

* Docker
* Docker Compose v2
* collection `community.docker`
* monitoring-хост с VictoriaMetrics, если нужен scrape config reload

## Переменные

| Переменная | Описание | По умолчанию |
| --- | --- | --- |
| `docker_network_name` | Docker network | `""` |
| `blackbox_exporter_docker_dir` | Рабочий каталог compose | `/home/{{ username }}/{{ blackbox_exporter_container_name }}` |
| `blackbox_exporter_repository` | Образ | `prom/blackbox-exporter` |
| `blackbox_exporter_config_path` | Путь к конфигу в контейнере | `/etc/blackbox-exporter/blackbox.yaml` |
| `blackbox_exporter_version` | Версия | `0.28.0` |
| `blackbox_exporter_container_name` | Имя контейнера | `blackbox_exporter` |
| `blackbox_exporter_port` | Порт | `9115` |
| `blackbox_exporter_restart_policy` | Restart policy | `unless-stopped` |
| `blackbox_exporter_url` | Hostname для Traefik | `blackbox.home.local` |
| `blackbox_tls_enabled` | Включить TLS labels | `false` |
| `blackbox_exporter_basic_auth_enabled` | Включить Basic Auth | `false` |
| `blackbox_exporter_basic_auth_username` | Пользователь | `admin` |
| `blackbox_exporter_basic_auth_password` | Пароль | `admin` |
| `blackbox_scrape_config_dir` | Каталог scrape-конфига на monitoring-хосте | `""` |
| `monitoring_server_groups` | Имя inventory-группы monitoring | `""` |

## Логика работы

1. Роль проверяет, запущен ли контейнер `{{ blackbox_exporter_container_name }}`.
2. Если контейнер уже работает, повторная установка пропускается.
3. Если контейнера нет или он остановлен, выполняется `install.yaml`.
4. В процессе установки также генерируется `blackbox-scrape-config.yaml`.
5. После копирования scrape-конфига вызывается handler на reload VictoriaMetrics.

## Пример

```yaml
- hosts: blackbox-server
  become: true
  roles:
    - role: blackbox-exporter
```
