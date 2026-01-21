
# Ansible role: `blackbox-exporter`

Кратко: роль разворачивает Prometheus Blackbox Exporter в Docker Compose на целевом хосте, интегрируется с Traefik и поддерживает опции базовой авторизации, кастомную конфигурацию модулей и внешнюю docker‑сеть.

Ключевые идеи
- Рендерит `docker-compose.yaml` из `templates/docker-compose.yaml.j2` и копирует `files/blackbox.yaml` в `blackbox_exporter_docker_dir` на целевом хосте.
- Использует `community.docker.docker_compose_v2` для запуска Compose (требуется Compose v2 на managed node).
- Ожидает внешнюю docker‑сеть (переменная `docker_network_name`) для интеграции с другими сервисами (Traefik, monitoring).

Требования
- Control node: Ansible >= 2.15 + коллекция `community.docker`.
- Managed node: Docker >= 24 и Docker Compose v2 (`docker compose`).

Основные переменные (см. `defaults/main.yaml`)
- `blackbox_exporter_repository` — docker image (по умолчанию `prom/blackbox-exporter`).
- `blackbox_exporter_version` — версия образа (например `0.28.0`).
- `blackbox_exporter_container_name` — имя контейнера.
- `blackbox_exporter_port` — порт (по умолчанию `9115`).
- `blackbox_exporter_config_path` — путь к `blackbox.yaml` внутри контейнера.
- `blackbox_exporter_docker_dir` — директория на хосте с `docker-compose.yaml` и `blackbox.yaml`.
- `docker_network_name` — внешняя docker сеть (обязательно для Traefik интеграции).
- `blackbox_exporter_url` — Host для Traefik (пример: `blackbox.example.com`).
- `blackbox_exporter_basic_auth_enabled` — включить Traefik basic auth (false по умолчанию).

Traefik и basic auth
- `templates/docker-compose.yaml.j2` добавляет Traefik labels: `traefik.http.routers.<name>`, `traefik.http.services.<name>` и т.д. При расширении шаблона соблюдайте существующую схему имён.
- Роль может генерировать bcrypt‑hash: если вы передаёте `blackbox_exporter_basic_auth_password` в открытом виде, задача `tasks/install.yaml` создаст hash через `password_hash('bcrypt')`. Лучше хранить хеш или пароль в `ansible-vault`.

Файлы роли
- `defaults/main.yaml` — значения по умолчанию и рекомендуемые переменные.
- `templates/docker-compose.yaml.j2` — шаблон Compose с Traefik labels и монтируемыми томами.
- `files/blackbox.yaml` — пример списка модулей для `blackbox-exporter`.
- `tasks/main.yaml` и `tasks/install.yaml` — порядок действий: рендер, копирование, запуск через `docker compose`.

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
        # храните пароль/хеш в ansible-vault
        blackbox_exporter_basic_auth_password: "{{ vault_plain_password }}"
```

Проверка метрик и отладка
- Убедитесь, что на целевом хосте в `{{ blackbox_exporter_docker_dir }}` присутствуют `docker-compose.yaml` и `blackbox.yaml`.
- Проверка статуса контейнера и логов:
```bash
docker compose -f {{ blackbox_exporter_docker_dir }}/docker-compose.yaml ps
docker compose -f {{ blackbox_exporter_docker_dir }}/docker-compose.yaml logs -f
```
- Проверка доступности метрик (локально или с Prometheus):
```bash
curl -s http://<blackbox_host>:{{ blackbox_exporter_port }}/metrics | head -n 50
```
- Если Traefik используется, проверьте сертификаты/маршруты Traefik и, при включённом basic auth, корректность хеша/credentials.

Интеграция с Terraform/Ansible
- В этом репозитории Terraform генерирует inventory для Ansible через `terraform/inventory.tftpl`. Не меняйте имена outputs в Terraform без обновления шаблона inventory.
- Запуск ролей через главный playbook: `ansible/playbook.yaml`. Inventory для окружений находится в `ansible/inventories/`.

Советы безопасности
- Секреты храните в `ansible-vault` или в секретном хранилище облака — не коммитьте пароли в репозиторий.
- Если маршрутизация идёт через Traefik, не публикуйте порт контейнера наружу; используйте internal network + Traefik router.

