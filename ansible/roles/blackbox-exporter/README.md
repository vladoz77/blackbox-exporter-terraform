# Ansible Role: blackbox-exporter

Ansible-роль для установки и запуска **Prometheus Blackbox Exporter** в Docker через `docker-compose`.
Роль поддерживает TLS, Basic Auth (через Traefik) и автоматическую генерацию scrape-конфигурации для мониторинга (VictoriaMetrics / Prometheus).

Роль идемпотентна: проверяет, запущен ли контейнер, и выполняет действия только при необходимости.

---

## Возможности

* Установка **Blackbox Exporter** в Docker
* Автоматическая генерация `docker-compose.yaml` из шаблона
* Поддержка:

  * TLS
  * Basic Auth (через Traefik)
* Автоматическая генерация scrape-конфига для мониторинга
* Копирование scrape-конфига на указанный monitoring-сервер
* Hot-reload VictoriaMetrics после обновления scrape-конфига
* Проверка состояния контейнера и идемпотентный запуск

---

## Структура роли

```text
blackbox-exporter/
├── defaults
│   └── main.yaml              # Переменные по умолчанию
├── files
│   └── blackbox.yaml          # Конфиг Blackbox Exporter
├── handlers
│   └── main.yaml              # Reload VictoriaMetrics
├── tasks
│   ├── generate-password-hash.yaml # Генерация bcrypt пароля для Traefik
│   ├── install.yaml           # Установка и запуск контейнера
│   └── main.yaml              # Проверка состояния контейнера
└── templates
    ├── docker-compose.yaml.j2 # Docker Compose
    └── blackbox-scrape-config.yaml.j2 # Scrape config
```

---

## Требования

* Docker
* Docker Compose v2
* Ansible collection: `community.docker`
* Traefik (опционально для TLS и Basic Auth)
* VictoriaMetrics / Prometheus с поддержкой `/-/reload`

---

## Переменные роли

### Основные

| Переменная                              | Описание                             | По умолчанию                                 |
| --------------------------------------- | ------------------------------------ | -------------------------------------------- |
| `blackbox_exporter_container_name`      | Имя Docker-контейнера                | `blackbox_exporter`                          |
| `blackbox_exporter_version`             | Версия Blackbox Exporter             | `0.28.0`                                     |
| `blackbox_exporter_port`                | Порт сервиса                         | `9115`                                       |
| `blackbox_exporter_repository`          | Docker-образ                         | `prom/blackbox-exporter`                     |
| `blackbox_exporter_docker_dir`          | Каталог с docker-compose             | `/home/{{ ansible_user }}/blackbox_exporter` |
| `blackbox_exporter_config_path`         | Путь к конфигу внутри контейнера     | `/etc/blackbox-exporter/blackbox.yaml`       |
| `docker_network_name`                   | Docker network                       | "" (по умолчанию default)                    |
| `blackbox_exporter_restart_policy`      | Политика рестарта контейнера         | `unless-stopped`                             |
| `blackbox_exporter_url`                 | DNS / URL для Traefik                | `blackbox.home.local`                        |
| `blackbox_tls_enabled`                  | Использовать TLS                     | `false`                                      |
| `blackbox_exporter_basic_auth_enabled`  | Включить Basic Auth                  | `false`                                      |
| `blackbox_exporter_basic_auth_username` | Пользователь для Basic Auth          | `admin`                                      |
| `blackbox_exporter_basic_auth_password` | Пароль для Basic Auth                | `admin`                                      |
| `blackbox_scrape_config_dir`            | Каталог для scrape-конфига           | ""                                           |
| `monitoring_server_groups`              | Ansible группа с monitoring сервером | ""                                           |

> Если включен Basic Auth, пароль автоматически хешируется с использованием bcrypt для Traefik.

---

## Handlers

### Reload VictoriaMetrics

Отправляет `POST` запрос на `/reload`:

```yaml
- POST https://<victoriametrics>/-/reload
```

* Повторы: 10
* Задержка: 5 секунд
* Сертификаты TLS не проверяются (`validate_certs: false`)

## Логика работы роли

1. Проверяет, существует ли контейнер и запущен ли он
2. Если контейнер **работает** — роль завершает выполнение
3. Если контейнер **не существует или остановлен**:

   * Создаёт каталог для docker-compose
   * Копирует конфиг `blackbox.yaml`
   * Генерирует `docker-compose.yaml` из шаблона
   * Создаёт пароль для Basic Auth (при необходимости)
   * Запускает контейнер через Docker Compose
4. Генерирует scrape-конфиг `blackbox-scrape-config.yaml`
5. Делегирует копирование scrape-конфига на monitoring-сервер
6. Выполняет reload VictoriaMetrics


## Пример использования

```yaml
- hosts: blackbox
  become: true
  vars:
    docker_network_name: monitoring
    blackbox_exporter_url: blackbox.example.com
    blackbox_exporter_basic_auth_enabled: true
    blackbox_exporter_basic_auth_password: supersecret
    blackbox_scrape_config_dir: /etc/victoriametrics/scrape
    monitoring_server_groups: monitoring
  roles:
    - role: blackbox-exporter
```
