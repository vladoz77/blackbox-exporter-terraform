# Ansible Role: blackbox-exporter

Ansible-роль для установки и запуска **Prometheus Blackbox Exporter** в Docker с помощью `docker-compose`.
Роль также автоматически обновляет конфигурацию мониторинга (VictoriaMetrics / Prometheus) и инициирует hot-reload.

## Возможности

* Установка **Blackbox Exporter** в Docker
* Генерация `docker-compose.yaml` из шаблона
* Поддержка:

  * TLS
  * Basic Auth (через Traefik)
* Генерация scrape-конфигурации для мониторинга
* Автоматический reload VictoriaMetrics
* Идемпотентный запуск (проверка, запущен ли контейнер)

## Структура роли

```text
ansible-blackbox-exporter/
├── defaults
│   └── main.yaml              # Переменные по умолчанию
├── files
│   └── blackbox.yaml          # Конфигурация Blackbox Exporter
├── handlers
│   └── main.yaml              # Reload VictoriaMetrics
├── tasks
│   ├── install.yaml           # Установка и запуск контейнера
│   └── main.yaml              # Проверка состояния контейнера
├── templates
│   ├── docker-compose.yaml.j2 # Docker Compose
│   └── blackbox-scrape-config.yaml.j2 # Scrape config
└── README.md
```

---

## Требования

* Docker
* Docker Compose v2
* Ansible `community.docker` collection
* Traefik (опционально, для TLS и Basic Auth)
* VictoriaMetrics или Prometheus с поддержкой `/-/reload`

---

## Переменные роли

### Основные

| Переменная                         | Описание                 | По умолчанию                                 |
| ---------------------------------- | ------------------------ | -------------------------------------------- |
| `blackbox_exporter_container_name` | Имя контейнера           | `blackbox_exporter`                          |
| `blackbox_exporter_version`        | Версия Blackbox Exporter | `0.28.0`                                     |
| `blackbox_exporter_port`           | Порт сервиса             | `9115`                                       |
| `blackbox_exporter_repository`     | Docker-образ             | `prom/blackbox-exporter`                     |
| `blackbox_exporter_docker_dir`     | Каталог с docker-compose | `/home/{{ ansible_user }}/blackbox_exporter` |

---

### Docker / Network

| Переменная                         | Описание                          |
| ---------------------------------- | --------------------------------- |
| `docker_network_name`              | Внешняя Docker-сеть (опционально) |
| `blackbox_exporter_restart_policy` | Политика рестарта контейнера      |

---

### DNS / URL

| Переменная                      | Описание                         |
| ------------------------------- | -------------------------------- |
| `blackbox_exporter_url`         | DNS-имя Blackbox Exporter        |
| `blackbox_exporter_config_path` | Путь к конфигу внутри контейнера |

---

### TLS и Basic Auth

| Переменная                              | Описание            | По умолчанию |
| --------------------------------------- | ------------------- | ------------ |
| `blackbox_tls_enabled`                  | Использовать TLS    | `false`      |
| `blackbox_exporter_basic_auth_enabled`  | Включить Basic Auth | `false`      |
| `blackbox_exporter_basic_auth_username` | Пользователь        | `admin`      |
| `blackbox_exporter_basic_auth_password` | Пароль              | `admin`      |

> Пароль автоматически хешируется (`bcrypt`) для Traefik.

---

### Monitoring / Scrape

| Переменная                   | Описание                             |
| ---------------------------- | ------------------------------------ |
| `blackbox_scrape_config_dir` | Каталог для scrape-конфига           |
| `monitoring_server_groups`   | Ansible group с сервером мониторинга |

Scrape-конфигурация:

* генерируется шаблоном
* копируется на monitoring-сервер
* вызывает reload VictoriaMetrics

---

## Handlers

### Reload VictoriaMetrics

```yaml
- POST https://<victoriametrics>/-/reload
```

* Повторы: `10`
* Задержка: `5s`
* Без проверки TLS сертификатов

---

## Пример использования

### Playbook

```yaml
- hosts: blackbox
  roles:
    - role: ansible-blackbox-exporter
      vars:
        docker_network_name: monitoring
        blackbox_exporter_url: blackbox.example.com
        blackbox_exporter_basic_auth_enabled: true
        blackbox_exporter_basic_auth_password: supersecret
        blackbox_scrape_config_dir: /etc/victoriametrics/scrape
        monitoring_server_groups: monitoring
```

## Логика работы роли

1. Проверяет, запущен ли контейнер
2. Если контейнер **работает** — роль ничего не делает
3. Если контейнер **не существует или остановлен**:

   * создаёт каталог
   * копирует конфиги
   * генерирует `docker-compose.yaml`
   * запускает контейнер
4. Генерирует scrape-конфиг
5. Делегирует копирование на monitoring-сервер
6. Выполняет hot-reload VictoriaMetrics



