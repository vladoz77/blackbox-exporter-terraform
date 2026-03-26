# Ansible Role: traefik

Роль разворачивает Traefik в Docker и синхронизирует `acme.json` с S3-совместимым хранилищем.

## Возможности

* запуск Traefik через Docker Compose
* Let's Encrypt staging и production
* Docker provider с `exposedByDefault = false`
* редирект HTTP -> HTTPS
* опциональный dashboard
* восстановление и загрузка `acme.json` в Object Storage

## Структура

```text
traefik/
├── defaults/
│   └── main.yaml
├── tasks/
│   ├── install.yaml
│   ├── main.yaml
│   └── sync.yaml
├── templates/
│   └── docker-compose-traefik.yaml.j2
├── requirements.yaml
└── README.md
```

## Требования

* Docker
* Docker Compose v2
* collections `community.docker` и `amazon.aws`
* доступ к 80/tcp и 443/tcp

Установка коллекций:

```bash
ansible-galaxy collection install -r ansible/roles/traefik/requirements.yaml
```

## Переменные

### Основные

| Переменная | Описание | По умолчанию |
| --- | --- | --- |
| `docker_network_name` | Docker-сеть Traefik | `traefik` |
| `traefik_container_name` | Имя контейнера | `traefik` |
| `traefik_image` | Имя image | `traefik` |
| `traefik_version` | Версия Traefik | `v3.6` |
| `traefik_docker_dir` | Рабочий каталог | `/home/{{ ansible_user }}/{{ traefik_container_name }}` |

### Dashboard

| Переменная | Описание | По умолчанию |
| --- | --- | --- |
| `traefik_enable_dashboard` | Включить dashboard | `false` |
| `traefik_dashboard_url` | Hostname dashboard | `traefik.home.local` |
| `traefik_dashboard_user` | Basic Auth username | `admin` |
| `traefik_dashboard_password_hash` | htpasswd hash | `$$apr1$$CmiVRFjs$$bPQcSgQ.2HcTzM.HVTvAl1` |

### ACME и S3

| Переменная | Описание | По умолчанию |
| --- | --- | --- |
| `traefik_acme_staging` | Использовать staging CA | `false` |
| `acme_email` | Email для Let's Encrypt | `vladoz77@yandex.ru` |
| `traefik_letsencrypt_path` | Каталог для ACME-файлов | `{{ traefik_docker_dir }}/letsencrypt` |
| `traefik_acme_file_staging` | Путь к staging JSON | `{{ traefik_letsencrypt_path }}/acme-staging.json` |
| `traefik_acme_file_prod` | Путь к prod JSON | `{{ traefik_letsencrypt_path }}/acme-prod.json` |
| `traefik_acme_sync_to_s3` | Синхронизировать с S3 | `true` |
| `yandex_region` | Регион Object Storage | `ru-central1` |
| `yandex_storage_endpoint` | Endpoint | `https://storage.yandexcloud.net/` |
| `s3_bucket_name` | Имя bucket | `acme-bucket` |
| `s3_key_staging` | Ключ staging | `{{ ansible_facts['hostname'] }}/acme-staging.json` |
| `s3_key_prod` | Ключ prod | `{{ ansible_facts['hostname'] }}/acme-prod.json` |

`aws_access_key` и `aws_secret_key` должны передаваться через inventory, `group_vars` или CI secrets.

## Логика работы

1. Роль проверяет, существует ли контейнер Traefik.
2. Если контейнера нет или он не запущен, выполняется `install.yaml`.
3. После этого, если `traefik_acme_sync_to_s3` включён, выполняется `sync.yaml`.

## Пример

```yaml
- hosts: edge
  become: true
  roles:
    - role: docker
    - role: traefik
```
