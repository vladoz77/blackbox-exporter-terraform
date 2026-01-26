# Ansible Role: traefik

Ansible-роль для установки и управления **Traefik v3** в Docker с поддержкой:

* автоматического HTTPS через **Let’s Encrypt**
* **staging / production** ACME
* синхронизации `acme.json` с **S3 (Yandex Object Storage)**
* Docker provider
* (опционально) Traefik Dashboard с Basic Auth

Роль предназначена для использования как **edge reverse-proxy** для сервисов в Docker.

## Возможности

* Установка Traefik через **Docker Compose v2**
* Автоматическое получение и обновление TLS-сертификатов
* Поддержка **Let’s Encrypt staging / production**
* Синхронизация `acme.json` в **S3**:

  * восстановление сертификатов при пересоздании хоста
  * единая точка хранения
* Docker provider (`exposedByDefault = false`)
* HTTP → HTTPS redirect
* Отдельная Docker-сеть для Traefik
* Опциональный Dashboard с Basic Auth


## Структура роли

```text
traefik/
├── defaults
│   └── main.yaml              # Переменные по умолчанию
├── tasks
│   ├── main.yaml              # Проверка контейнера + orchestration
│   ├── install.yaml           # Установка Traefik
│   └── sync.yaml              # Синхронизация acme.json с S3
├── templates
│   └── docker-compose-traefik.yaml.j2
└── README.md
```

## Требования

* Docker
* Docker Compose v2
* Ansible collections:

  * `community.docker`
  * `amazon.aws`
* Доступ к:

  * 80/tcp
  * 443/tcp
* S3-совместимое хранилище (Yandex Object Storage)

## Переменные роли

### Общие

| Переменная               | Описание            | По умолчанию                       |
| ------------------------ | ------------------- | ---------------------------------- |
| `docker_network_name`    | Docker-сеть Traefik | `traefik`                          |
| `traefik_container_name` | Имя контейнера      | `traefik`                          |
| `traefik_image`          | Docker image        | `traefik`                          |
| `traefik_version`        | Версия Traefik      | `v3.5`                             |
| `traefik_docker_dir`     | Рабочая директория  | `/home/{{ ansible_user }}/traefik` |

### Dashboard

| Переменная                        | Описание                | По умолчанию         |
| --------------------------------- | ----------------------- | -------------------- |
| `traefik_enable_dashboard`        | Включить dashboard      | `false`              |
| `traefik_dashboard_url`           | DNS имя dashboard       | `traefik.home.local` |
| `traefik_dashboard_user`          | Пользователь Basic Auth | `admin`              |
| `traefik_dashboard_password_hash` | htpasswd-хэш            | `admin:admin`        |

> ⚠️ Dashboard защищён **Basic Auth** и не публикуется, если `traefik_enable_dashboard = false`

### Let’s Encrypt / ACME

| Переменная                  | Описание                | По умолчанию                           |
| --------------------------- | ----------------------- | -------------------------------------- |
| `traefik_acme_staging`      | Использовать staging CA | `false`                                |
| `acme_email`                | Email для LE            | `vladoz77@yandex.ru`                   |
| `traefik_letsencrypt_path`  | Путь к acme.json        | `{{ traefik_docker_dir }}/letsencrypt` |
| `traefik_acme_file_staging` | ACME staging файл       | `acme-staging.json`                    |
| `traefik_acme_file_prod`    | ACME prod файл          | `acme-prod.json`                       |

### S3 (Yandex Object Storage)

| Переменная                | Описание               |
| ------------------------- | ---------------------- |
| `traefik_acme_sync_to_s3` | Включить синхронизацию |
| `yandex_region`           | Регион                 |
| `yandex_storage_endpoint` | S3 endpoint            |
| `s3_bucket_name`          | Bucket                 |
| `s3_key_staging`          | Ключ staging           |
| `s3_key_prod`             | Ключ production        |
| `aws_access_key`          | Access Key             |
| `aws_secret_key`          | Secret Key             |

## Пример использования

```yaml
- hosts: edge
  become: true
  roles:
    - role: docker
    - role: traefik
```

## Логика работы роли

1. Проверяется, запущен ли контейнер Traefik
2. Если Traefik не запущен:

   * устанавливаются зависимости
   * создаётся docker-compose конфигурация
   * подготавливается `acme.json`

     * скачивается из S3 **или**
     * создаётся пустой файл
3. Traefik запускается через Docker Compose
4. После запуска:

   * `acme.json` синхронизируется обратно в S3

## ACME и S3 — зачем это нужно

* Traefik **хранит сертификаты локально**
* При пересоздании сервера сертификаты будут потеряны
* Эта роль:

  * восстанавливает `acme.json` из S3
  * сохраняет обновлённые сертификаты обратно

✅ безопасно
✅ удобно
✅ без rate-limit проблем у Let’s Encrypt

---

## Docker provider

Traefik автоматически обнаруживает сервисы с лейблами:

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.app.rule=Host(`app.example.com`)"
  - "traefik.http.routers.app.entrypoints=websecure"
  - "traefik.http.routers.app.tls.certresolver=le"
```

По умолчанию сервисы **не публикуются**, если `traefik.enable != true`.

## Best Practices

* Использовать **staging** при первом запуске
* Хранить `acme.json` только в S3
* Всегда использовать отдельную Docker-сеть
* Не включать dashboard в публичных окружениях
* Для production — ограничить доступ к 80/443 firewall’ом
