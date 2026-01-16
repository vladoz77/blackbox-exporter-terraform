# Роль Ansible: blackbox-exporter

Кратко: разворачивает Prometheus Blackbox Exporter в Docker Compose на целевом хосте, интегрируется с Traefik и опционально включает базовую аутентификацию.

Ключевые идеи
- Роль рендерит `docker-compose.yaml` из `templates/docker-compose.yaml.j2` и копирует `files/blackbox.yaml` в рабочую директорию `blackbox_exporter_docker_dir`.
- Compose-проекты запускаются через `community.docker.docker_compose_v2` и подключаются к внешней Docker-сети (`docker_network_name`).

Требования
- Control node: Ansible >= 2.15, коллекция `community.docker`.
- Managed node: Docker >= 24, Docker Compose v2 (`docker compose`).
- Должна существовать внешняя docker-сеть, указанная в `docker_network_name`.

Главные переменные (см. `defaults/main.yaml`)
- `blackbox_exporter_repository` — образ (default: `prom/blackbox-exporter`).
- `blackbox_exporter_version` — версия образа (default: `0.28.0`).
- `blackbox_exporter_container_name` — имя контейнера.
- `blackbox_exporter_port` — порт внутри/снаружи (default: `9115`).
- `blackbox_exporter_config_path` — путь конфигурации внутри контейнера.
- `blackbox_exporter_docker_dir` — директория на хосте для файлов compose и config.
- `blackbox_exporter_url` — Host для Traefik (пример: `blackbox.example.com`).
- `blackbox_exporter_basic_auth_enabled` — включить Traefik basic auth (false по умолчанию).

Traefik и auth
- Шаблон `templates/docker-compose.yaml.j2` добавляет labels для Traefik: `traefik.http.routers.<name>`, `traefik.http.services.<name>`. Используйте такую же схему при добавлении сервисов.
- Хеш пароля генерируется в задаче `tasks/install.yaml` через `password_hash(hashtype='bcrypt')`. Когда включаете auth, передавайте `blackbox_exporter_basic_auth_password` (или храните hash в `ansible-vault`).

Файлы роли
- `defaults/main.yaml` — значения по умолчанию.
- `templates/docker-compose.yaml.j2` — compose-шаблон с Traefik метками.
- `files/blackbox.yaml` — пример конфигурации blackbox modules.
- `tasks/main.yaml`, `tasks/install.yaml` — логика проверки, копирования и запуска.

Пример использования (playbook)
```yaml
- hosts: blackbox-server
  become: true
  roles:
    - role: blackbox-exporter
      vars:
        blackbox_exporter_url: "blackbox.example.com"
        blackbox_exporter_basic_auth_enabled: true
        blackbox_exporter_basic_auth_username: "admin"
        # храните пароль в ansible-vault; роль может сгенерировать bcrypt hash из plain
        blackbox_exporter_basic_auth_password: "{{ vault_plain_password }}"
```

Советы по отладке
- Убедитесь, что в `{{ blackbox_exporter_docker_dir }}` лежат `docker-compose.yaml` и `blackbox.yaml`.
- На целевой VM можно просмотреть логи:
```
docker compose -f /home/ubuntu/blackbox_exporter/docker-compose.yaml ps
docker compose -f /home/ubuntu/blackbox_exporter/docker-compose.yaml logs -f
```

Безопасность и практики
- Секреты и пароли храните в `ansible-vault`.
- При использовании Traefik обязательно проверяйте TLS (certresolver) и не публикуйте контейнерные порты наружу, если маршрутизация идёт через Traefik.

Где смотреть примеры
- Посмотрите `ansible/roles/blackbox-exporter/templates/docker-compose.yaml.j2` для примера Traefik labels.
- Шаблон генерации inventory — `terraform/inventory.tftpl`.

Если нужно — добавлю короткий пример для Molecule или тестовый playbook для локальной отладки.
