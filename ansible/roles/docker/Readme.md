# Ansible Role: docker

Роль устанавливает Docker Engine и подготавливает хост для запуска остальных сервисов проекта.

## Что делает роль

* выбирает набор задач по `ansible_facts.os_family`
* устанавливает Docker CE и compose plugin
* запускает и включает `docker.service`
* создаёт внешнюю docker network

## Структура

```text
docker/
├── defaults/
│   └── main.yaml
├── handlers/
│   └── main.yaml
├── tasks/
│   ├── main.yaml
│   ├── rhel.yaml
│   └── ubuntu.yaml
├── vars/
│   ├── rhel
│   └── ubuntu
└── Readme.md
```

## Поддерживаемые ОС

* Debian family
* RedHat family

Конкретный сценарий выбирается в `tasks/main.yaml`.

## Переменные

### `defaults/main.yaml`

| Переменная | Описание | По умолчанию |
| --- | --- | --- |
| `docker_network_name` | Имя внешней docker network | `docker_default` |
| `docker_packages` | Пакеты Docker для Debian family | `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin`, `docker-compose-plugin` |
| `docker_service_name` | Имя systemd-сервиса | `docker.service` |

### `vars/ubuntu`

* `docker_repo`
* `docker_gpg_key`

### `vars/rhel`

* `repo_url`
* `repo_dest`
* `packages`
* `docker_service_name`

## Логика работы

1. Роль определяет семейство ОС.
2. Подключает `ubuntu.yaml` или `rhel.yaml`.
3. Устанавливает Docker из официального репозитория для выбранной платформы.
4. Запускает Docker и создаёт сеть `{{ docker_network_name }}`.

## Пример

```yaml
- hosts: all
  become: true
  roles:
    - role: docker
```
