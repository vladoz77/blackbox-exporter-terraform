# Ansible Role: grafana-alloy

Роль устанавливает Grafana Alloy как systemd-сервис и настраивает локальный агент для отправки telemetry.

## Возможности

* healthcheck перед установкой
* скачивание и распаковка бинарника Alloy
* создание пользователя `alloy`
* генерация `config.alloy` и `alloy.service`
* валидация конфига и unit-файла
* немедленный `flush_handlers` после изменения шаблонов

## Структура

```text
grafana-alloy/
├── defaults/
│   └── main.yaml
├── handlers/
│   └── main.yaml
├── tasks/
│   ├── alloy-config.yaml
│   ├── alloy-install.yaml
│   └── main.yaml
├── templates/
│   ├── alloy.service.j2
│   └── config.alloy.j2
├── vars/
│   └── main.yaml
└── README.md
```

## Требования

* Linux с `systemd`
* доступ в интернет для скачивания релиза Alloy
* `apt` для установки `unzip`

## Переменные

### `defaults/main.yaml`

| Переменная | Описание | По умолчанию |
| --- | --- | --- |
| `alloy_version` | Версия Alloy | `v1.10.2` |
| `alloy_url_download` | URL архива | `https://github.com/grafana/alloy/releases/download/{{ alloy_version }}/alloy-linux-amd64.zip` |
| `alloy_config_dir` | Каталог конфигурации | `/etc/alloy` |
| `alloy_storage_dir` | Каталог данных | `/var/lib/alloy` |
| `alloy_username` | Системный пользователь | `alloy` |
| `alloy_groups` | Дополнительные группы | `adm`, `systemd-journal`, `docker` |
| `alloy_enable_docker` | Включить docker-блок в шаблоне | `true` |
| `prometheus_url` | Адрес remote_write endpoint | `prometheus.home-local.site` |
| `alloy_prometheus_scheme` | Схема для Prometheus/VictoriaMetrics | `https` |
| `alloy_loki_scheme` | Схема для Loki | `http` |
| `alloy_skip_tls_verify` | Отключить TLS verify | `false` |
| `loki_url` | Адрес Loki | `loki.home-local.site` |
| `alloy_healthcheck_url` | Локальный health endpoint | `http://127.0.0.1:12345/-/healthy` |

### `vars/main.yaml`

| Переменная | Описание | По умолчанию |
| --- | --- | --- |
| `extract_dir` | Временный каталог | `/tmp` |
| `install_path` | Каталог установки бинарника | `/usr/local/bin` |
| `systemd_unit_dir` | Каталог unit-файлов | `/etc/systemd/system` |

## Логика работы

1. Проверяется `alloy_healthcheck_url`.
2. Если Alloy уже отвечает `200`, шаг установки бинарника пропускается.
3. Если healthcheck неуспешен, выполняется `alloy-install.yaml`.
4. Затем всегда выполняется `alloy-config.yaml`.
5. После шаблонизации роль вызывает `meta: flush_handlers`, чтобы рестарт Alloy произошёл в том же прогоне.

## Пример

```yaml
- hosts: all
  become: true
  roles:
    - role: grafana-alloy
```
