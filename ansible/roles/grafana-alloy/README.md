# Ansible Role: grafana-alloy

Ansible-роль для установки и настройки **Grafana Alloy** как systemd-сервиса.

## Возможности

* Проверка состояния Alloy через HTTP healthcheck
* Условная установка бинарника (только если Alloy не healthy)
* Создание системного пользователя `alloy`
* Подготовка директорий конфигурации и storage
* Генерация `config.alloy` и systemd unit из шаблонов
* Валидация:
  * `alloy validate` для конфига
  * `systemd-analyze verify` для unit-файла
* Рестарт Alloy через handler при изменении шаблонов

## Структура роли

```text
grafana-alloy/
├── defaults
│   └── main.yaml
├── handlers
│   └── main.yaml
├── tasks
│   ├── main.yaml
│   ├── alloy-install.yaml
│   └── alloy-config.yaml
├── templates
│   ├── alloy.service.j2
│   └── config.alloy.j2
├── vars
│   └── main.yaml
└── README.md
```

## Требования

* Linux-хост с `systemd`
* Пакетный менеджер `apt` (используется для установки `unzip`)
* Доступ в интернет для скачивания релиза Alloy

## Переменные роли

### defaults/main.yaml

| Переменная | Описание | По умолчанию |
| --- | --- | --- |
| `alloy_version` | Версия Alloy | `v1.10.2` |
| `alloy_url_download` | URL архива Alloy | `https://github.com/grafana/alloy/releases/download/{{ alloy_version }}/alloy-linux-amd64.zip` |
| `alloy_config_dir` | Каталог конфига | `/etc/alloy` |
| `alloy_storage_dir` | Каталог storage | `/var/lib/alloy` |
| `alloy_username` | Системный пользователь | `alloy` |
| `alloy_groups` | Доп. группы пользователя | `adm`, `systemd-journal`, `docker` |
| `alloy_enable_docker` | Включить docker-часть в шаблоне конфига | `true` |
| `prometheus_url` | Адрес remote_write Prometheus/VictoriaMetrics | `prometheus.home-local.site` |
| `alloy_prometheus_scheme` | Схема для Prometheus endpoint | `https` |
| `alloy_loki_scheme` | Схема для Loki endpoint | `http` |
| `alloy_skip_tls_verify` | Пропуск проверки TLS в remote_write | `false` |
| `loki_url` | Адрес Loki | `loki.home-local.site` |
| `alloy_healthcheck_url` | Health endpoint Alloy | `http://127.0.0.1:12345/-/healthy` |

### vars/main.yaml

| Переменная | Описание | По умолчанию |
| --- | --- | --- |
| `extract_dir` | Временный каталог для архива | `/tmp` |
| `install_path` | Путь установки бинарника | `/usr/local/bin` |
| `systemd_unit_dir` | Каталог systemd unit-файлов | `/etc/systemd/system` |

## Логика работы роли

1. Выполняется healthcheck `alloy_healthcheck_url`.
2. Если Alloy healthy (`HTTP 200`), установка бинарника пропускается.
3. Если Alloy не healthy, выполняется `tasks/alloy-install.yaml`:
   * установка `unzip`
   * скачивание архива Alloy
   * распаковка
   * копирование бинарника в `{{ install_path }}/alloy`
   * очистка временных файлов
4. Всегда выполняется `tasks/alloy-config.yaml`:
   * создание пользователя и директорий
   * шаблонизация `config.alloy` и `alloy.service`
5. При изменении шаблонов вызывается handler `restart alloy`.

## Handler

`handlers/main.yaml`:

* `restart alloy` -> `ansible.builtin.systemd` c:
  * `name: alloy`
  * `state: restarted`
  * `daemon_reload: yes`

## Пример использования

```yaml
- hosts: alloy
  become: true
  roles:
    - role: grafana-alloy
```

