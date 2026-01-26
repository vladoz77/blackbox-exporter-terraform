# Ansible Role: docker

Ansible-роль для установки и базовой настройки **Docker Engine** и сопутствующих компонентов на Linux-системах.
Поддерживаются дистрибутивы семейства **Debian/Ubuntu** и **RHEL/CentOS**.

Роль:

* устанавливает Docker из официального репозитория
* фиксирует версию пакетов (Ubuntu)
* добавляет пользователя в группу `docker`
* включает и запускает сервис Docker
* создаёт Docker-сеть

## Возможности

* Установка Docker CE
* Поддержка Ubuntu / Debian и RHEL / CentOS
* Контроль версии Docker
* Автоматический запуск и enable сервиса
* Создание внешней Docker-сети
* Идемпотентное выполнение (проверка существующего сервиса)

## Структура роли

```text
docker/
├── defaults
│   └── main.yaml        # Переменные по умолчанию
├── handlers
│   └── main.yaml        # Запуск и enable Docker
├── tasks
│   ├── main.yaml        # Выбор задач по OS
│   ├── ubuntu.yaml     # Установка для Debian/Ubuntu
│   └── rhel.yaml       # Установка для RHEL/CentOS
├── vars
│   ├── ubuntu.yaml     # Репозиторий и GPG для Ubuntu
│   └── rhel.yaml       # Репозиторий и пакеты для RHEL
└── README.md
```

## Поддерживаемые ОС

| ОС                | Статус                                    |
| ----------------- | ----------------------------------------- |
| Ubuntu            | ✅                                         |
| Debian            | ✅ (через Debian family)                   |
| RHEL / CentOS     | ✅                                         |
| Rocky / AlmaLinux | ⚠️ (не тестировалось, но должно работать) |

## Переменные роли

### Основные (defaults)

| Переменная            | Описание                    | По умолчанию     |
| --------------------- | --------------------------- | ---------------- |
| `docker_version`      | Версия Docker CE            | `5:28.5.2-1`     |
| `docker_service_name` | Имя сервиса Docker          | `docker.service` |
| `docker_network_name` | Имя создаваемой Docker-сети | `docker_default` |

### Пакеты (Ubuntu)

```yaml
docker_packages:
  - docker-ce
  - docker-ce-cli
  - containerd.io
  - docker-buildx-plugin
  - docker-compose-plugin
```

Версии пакетов жёстко фиксируются и **блокируются (`apt-mark hold`)**.

## Логика работы роли

1. Определяется семейство ОС (`Debian` / `RedHat`)
2. Подгружаются соответствующие переменные
3. Проверяется, установлен ли сервис Docker
4. Если Docker **не установлен**:

   * добавляется официальный репозиторий
   * устанавливаются пакеты
   * пользователь добавляется в группу `docker`
   * создаётся Docker-сеть
   * сервис Docker запускается и включается в автозапуск
5. Если Docker уже установлен — роль ничего не меняет

## Handlers

### Запуск Docker

```yaml
- name: started_docker
  systemd:
    name: docker.service
    state: started
    enabled: true
```

Вызывается после установки пакетов.

## Docker network

Роль создаёт внешнюю Docker-сеть:

```yaml
docker_network:
  name: "{{ docker_network_name }}"
```

Полезно для:

* Traefik
* Monitoring
* Связи между сервисами

## Пример использования

### Простой playbook

```yaml
- hosts: all
  become: true
  roles:
    - role: docker
```

### С кастомной сетью и версией

```yaml
- hosts: all
  become: true
  roles:
    - role: docker
      vars:
        docker_network_name: monitoring
        docker_version: "5:28.5.2-1"
```

