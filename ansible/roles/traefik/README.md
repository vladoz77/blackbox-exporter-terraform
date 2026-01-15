# Ansible Role: Traefik Reverse Proxy

Устанавливает и настраивает **Traefik v3.5** как reverse proxy с:
- 🔒 Автоматическими SSL сертификатами от Let's Encrypt (ACME)
- 📦 Интеграцией с Docker Compose (автоматическое обнаружение сервисов)
- ☁️ Резервным копированием `acme.json` в Yandex Cloud S3
- 📊 Опциональным Web Dashboard с базовой аутентификацией

## 📋 Requirements

### Target System
- **Ubuntu/Debian** (роль использует `apt`)
- **Docker** + **Docker Compose v2** (устанавливается ролью `docker`)
- **Python 3.x** с модулями `boto3`, `botocore`

### Ansible Collections
Требуются в playbook:
```yaml
collections:
  - amazon.aws            # Для S3 операций
  - community.docker      # Для Docker Compose
```

## ⚙️ Role Variables

### Docker конфигурация
```yaml
docker_network_name: "traefik"                              # Сеть для Traefik контейнера
traefik_container_name: "traefik"                          # Имя контейнера
traefik_image: "traefik"                                   # Docker образ (без версии)
traefik_version: "v3.5"                                    # Версия образа
traefik_docker_dir: "/home/{{ ansible_user }}/traefik"    # Рабочая директория
traefik_letsencrypt_path: "{{ traefik_docker_dir }}/letsencrypt"  # Хранилище сертификатов
```

### Let's Encrypt (ACME)
```yaml
acme_email: "vladoz77@yandex.ru"          # Email для уведомлений от Let's Encrypt
traefik_acme_staging: false               # true = staging (для тестирования), false = production

# Пути к файлам сертификатов (выбираются автоматически в зависимости от staging/prod)
traefik_acme_file_staging: "{{ traefik_letsencrypt_path }}/acme-staging.json"
traefik_acme_file_prod: "{{ traefik_letsencrypt_path }}/acme-prod.json"
```

### Dashboard (опционально)
```yaml
traefik_enable_dashboard: false                            # Включить Web интерфейс
traefik_dashboard_url: "traefik.home.local"               # Домен для доступа
traefik_dashboard_user: "admin"                            # Username для аутентификации
traefik_dashboard_password_hash: "$$apr1$$CmiVRFjs$$..."  # Хеш пароля (htpasswd формат)
```

**Генерация хеша пароля:**
```bash
# На локальной машине:
htpasswd -nb admin mypassword | cut -d: -f2
# Или через docker:
docker run --rm httpd htpasswd -nb admin mypassword | cut -d: -f2
```

### Yandex Cloud S3 интеграция
```yaml
traefik_acme_sync_to_s3: true                                    # Включить синхронизацию
yandex_region: "ru-central1"                                     # Регион облака
yandex_storage_endpoint: "https://storage.yandexcloud.net/"      # Endpoint S3
s3_bucket_name: "acme-bucket"                                    # Название бакета
s3_key_staging: "{{ ansible_hostname }}/acme-staging.json"      # Путь в S3 (staging)
s3_key_prod: "{{ ansible_hostname }}/acme-prod.json"            # Путь в S3 (production)

# ⚠️ ЧУВСТВИТЕЛЬНЫЕ ДАННЫЕ - передавать через:
# 1. ansible-vault (рекомендуется)
# 2. CLI флаг -e при запуске playbook (для CI/CD)
aws_access_key: "YCAJ..."  # Yandex Cloud Service Account key
aws_secret_key: "YCPM..."  # Yandex Cloud Service Account secret
```

## 🚀 Usage

### Базовая установка
```yaml
- hosts: blackbox-server
  vars:
    acme_email: "admin@example.com"
  roles:
    - traefik
```

### С Dashboard и S3 бэкапом
```yaml
- hosts: blackbox-server
  vars:
    acme_email: "admin@example.com"
    traefik_enable_dashboard: true
    traefik_dashboard_url: "traefik.home-local.site"
    traefik_acme_sync_to_s3: true
  roles:
    - traefik
```

**Передача AWS credentials (для CI/CD):**
```bash
ansible-playbook playbook.yaml \
  -e aws_access_key=YCAJ_xxx \
  -e aws_secret_key=YCPM_xxx
```

### С переменными из group_vars
Пример: `ansible/group_vars/blackbox-server.yaml`
```yaml
traefik_version: "v3.5"
traefik_enable_dashboard: true
traefik_dashboard_url: "traefik.home-local.site"
traefik_acme_staging: false
traefik_acme_sync_to_s3: true
# aws_access_key и aws_secret_key передать через -e флаг
```

## 🔧 Features

### ✅ Автоматическое управление SSL сертификатами
- **Let's Encrypt сертификаты** через HTTP challenge (порт 80)
- **Автоматическое продление** за 30 дней до истечения
- **HTTPS редирект** (все HTTP запросы → HTTPS)
- **Staging сертификаты** для тестирования (не требует DNS валидации)

### ✅ Docker интеграция
- **Автоматическое обнаружение сервисов** через Docker labels
- Поддержка **Docker Compose v2**
- Маршрутизация на основе **Host-header**
- Балансировка нагрузки между экземплярами

**Пример конфигурации для service:**
```yaml
services:
  victoriametrics:
    container_name: victoriametrics
    image: victoriametrics/victoria-metrics:latest
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.victoriametrics.rule=Host(`prometheus.home-local.site`)"
      - "traefik.http.routers.victoriametrics.entrypoints=websecure"
      - "traefik.http.routers.victoriametrics.tls.certresolver=le"
      - "traefik.http.services.victoriametrics.loadbalancer.server.port=8428"
    networks:
      - {{ docker_network_name }}  # ⚠️ Одна сеть с Traefik!
```

### ✅ Yandex Cloud S3 Backup
- **Автоматическое восстановление** `acme.json` из S3 при первой установке
- **Периодическая синхронизация** сертификатов в облако (задача `sync.yaml`)
- **Защита от потери** при пересоздании инстанса (терраформ destroy/apply)
- **Избежание лимитов** Let's Encrypt (60 запросов/час на домен)

### ✅ Dashboard (опционально)
- **Web-интерфейс мониторинга** Traefik (по умолчанию отключен)
- **Базовая HTTP аутентификация** (username/password)
- **HTTPS доступ** с автоматическими сертификатами
- **Отдельный домен** (не зависит от основного трафика)

## 🔄 Lifecycle

### Основной workflow (tasks/main.yaml)
1. **Проверка статуса контейнера** — проверяет, запущен ли Traefik
2. **Установка при необходимости** — выполняет `tasks/install.yaml` только если контейнер не найден или остановлен
3. **Синхронизация в S3** — выполняет `tasks/sync.yaml` для резервного копирования `acme.json`

### Установка (tasks/install.yaml)
1. Обновление apt кэша и установка зависимостей
2. Создание директории `{{ traefik_docker_dir }}`
3. **Восстановление сертификатов из S3** (если они существуют в облаке)
4. Создание пустого `acme.json` (если не найден ни локально, ни на S3)
5. Установка правильных прав доступа (600)
6. Рендеринг `docker-compose.yaml` из шаблона
7. Запуск контейнера через `community.docker.docker_compose_v2`

### Синхронизация (tasks/sync.yaml)
1. Проверка наличия `acme.json` локально
2. Проверка что файл не пустой (защита от перезаписи)
3. Загрузка `acme.json` на S3 (всегда перезаписывает)

## 🔒 Security Notes

### Хранение AWS credentials
**Вариант 1: Передача через CLI (для CI/CD)**
```bash
ansible-playbook playbook.yaml \
  -e aws_access_key=$AWS_ACCESS_KEY \
  -e aws_secret_key=$AWS_SECRET_KEY
```

**Вариант 2: ansible-vault (для локального запуска)**
```bash
# Создать encrypted файл
ansible-vault create group_vars/vault.yml

# Содержимое:
aws_access_key: "YCAJ..."
aws_secret_key: "YCPM..."

# Запуск с vault
ansible-playbook playbook.yaml --ask-vault-pass
```

### Безопасность Dashboard
- ⚠️ **По умолчанию отключен** (`traefik_enable_dashboard: false`)
- **Обязательная базовая аутентификация** при включении
- **Используйте отдельный домен** (не на главном домене приложения)
- **Сложные пароли** — минимум 12 символов с буквами, цифрами, спецсимволами

## 📁 Role Structure
```
traefik/
├── README.md                                # Этот файл
├── defaults/main.yaml                       # Переменные по умолчанию
├── tasks/
│   ├── main.yaml                           # Основная логика (идемпотентно)
│   ├── install.yaml                        # Установка и первоначальная настройка
│   └── sync.yaml                           # Синхронизация acme.json в S3
├── templates/
│   └── docker-compose-traefik.yaml.j2      # Docker Compose конфигурация
└── handlers/
    └── main.yaml                           # Обработчики (если требуются)
```

## 🔍 Troubleshooting

### Проверка статуса Traefik
```bash
# На хосте:
docker ps | grep traefik
docker logs traefik
```

### Проверка сертификатов
```bash
# Просмотр всех сертификатов
docker exec traefik traefik certs list

# Проверка конкретного сертификата
docker exec traefik ls -la /letsencrypt/
```

### Проверка Dashboard
```bash
# Если включен dashboard
curl -u admin:password https://traefik.home-local.site/api/health
curl -u admin:password https://traefik.home-local.site/dashboard/
```

### Проверка S3 синхронизации
```bash
# На целевом хосте проверить, есть ли файл acme.json
ls -la ~/traefik/letsencrypt/

# Проверить логи Ansible для ошибок S3
# grep "sync asme file to s3" из вывода Ansible
```

### Исправление потерянных сертификатов
```bash
# Если acme.json потерян, а сертификаты были в S3:
1. Удалить контейнер: docker rm -f traefik
2. Запустить роль заново — она восстановит acme.json из S3
```

## 📊 Monitoring

### Логи Traefik
```bash
docker logs -f traefik
```

### Статус доступных маршрутов
```bash
docker logs traefik | grep "routers"
```

### Health check
```bash
# Базовый health check
curl http://localhost:8080/api/health

# Через Traefik на HTTPS
curl -k https://traefik.home-local.site/api/health
```

## 🎯 Best Practices

1. **Staging перед production**
   ```yaml
   traefik_acme_staging: true  # Сначала тестируем на staging
   # После успешного теста — переходим на production
   traefik_acme_staging: false
   ```

2. **Резервное копирование S3**
   - Всегда включайте `traefik_acme_sync_to_s3: true` в production
   - Проверяйте, что AWS credentials верные перед первым запуском
   - Регулярно проверяйте логи синхронизации

3. **Dashboard безопасность**
   - Не включайте на машинах с публичным доступом без VPN
   - Используйте сложные пароли
   - Регулярно проверяйте логи доступа

4. **Мониторинг сертификатов**
   - Настройте алерты на истечение сертификатов (>30 дней до истечения)
   - Проверяйте логи Traefik на ошибки ACME

## 🐛 Common Issues

### "acme.json not found" после создания VM
- Это нормально — будет создан новый файл Let's Encrypt запросит сертификат
- Если был S3 бэкап — файл восстановится автоматически

### Dashboard недоступен
- Проверьте `traefik_enable_dashboard: true` в переменных
- Убедитесь DNS разрешается на IP хоста
- Проверьте `traefik_dashboard_url` соответствует DNS

### "Too many requests" от Let's Encrypt
- Это случается при многих переустановках на staging
- Используйте `traefik_acme_staging: true` для тестирования
- Production лимит восстанавливается за час

### S3 upload fails
- Проверьте AWS credentials (aws_access_key, aws_secret_key)
- Убедитесь Service Account имеет права на запись в бакет
- Проверьте endpoint: `https://storage.yandexcloud.net/`

## 📚 See Also

- [Traefik Documentation](https://doc.traefik.io/)
- [ACME Configuration](https://doc.traefik.io/traefik/https/acme/)
- [Docker Provider](https://doc.traefik.io/traefik/providers/docker/)
- [Yandex Cloud S3](https://cloud.yandex.ru/docs/storage/)
