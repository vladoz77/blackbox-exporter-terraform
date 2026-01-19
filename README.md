# Blackbox Exporter — Terraform + Ansible

Подробная документация по инфраструктурному репозиторию для развёртывания Prometheus Blackbox Exporter с помощью Terraform (создание инстансов/сети) и Ansible (конфигурация и запуск в Docker Compose).

## Назначение

Репозиторий содержит IaC для создания облачной инфраструктуры (виртуальные машины, сеть, security groups) и последующего развёртывания `blackbox-exporter` на этих машинах с помощью Ansible. Цель — обеспечить повторяемое, контролируемое и версионируемое развёртывание для `stage` и `prod` окружений.

## Архитектура

- Terraform создаёт ресурсы в облаке (модуль `modules/yc-instance` используется как пример для инстансов).
- Terraform экспортирует адреса/данные инстансов, которые используются для генерации Ansible inventory.
- Ansible устанавливает Docker, деплоит `docker-compose` и разворачивает `blackbox-exporter` на целевых машинах.
- Дополнительно есть роли для мониторинга, alertmanager, grafana и т.д.

## Быстрый старт

1) Клонируйте репозиторий и перейдите в каталог проекта:

```bash
git clone <репозиторий>
cd blackbox-exporter-terraform
```

2) Подготовьте `tfvars` для выбранного окружения (пример — `terraform/environment/prod-terraform.tfvars`):

```bash
cp terraform/environment/prod-terraform.tfvars.example terraform/environment/prod-terraform.tfvars
# отредактируйте terraform/environment/prod-terraform.tfvars
```

3) Инициализируйте и примените Terraform:

```bash
cd terraform
terraform init
terraform plan -var-file=environment/prod-terraform.tfvars
terraform apply -var-file=environment/prod-terraform.tfvars
```

4) После успешного apply получите выходные переменные (`terraform output`) — они могут включать IP-адреса и шаблоны для Ansible inventory.

5) Запустите Ansible playbook для развёртывания (пример для prod):

```bash
cd ../ansible
ansible-playbook -i inventories/prod playbook.yaml
```

## Подготовка окружения (детали)

- Установите Terraform (рекомендованная версия указывается в `terraform/.terraform-version` или в документации модуля).
- Установите Ansible (рекомендуется >=2.9). Если используете control machine на Linux, установите `pip` и выполните `pip install ansible`.
- Настройте доступ к облаку (ключи/credentials) согласно провайдеру, который использует Terraform (см. `terraform/main.tf`).

## Terraform: советы и переменные

- Файлы конфигурации: `terraform/main.tf`, `terraform/variables.tf`, `terraform/output.tf`, `terraform/network.tf`.
- Используйте `terraform plan` перед `apply`.
- Примеры переменных для `prod` и `stage` находятся в `terraform/environment/`.
- Для генерации инвентаря Ansible используется шаблон `terraform/inventory.tftpl` — проверьте outputs в `terraform/output.tf`.

## Ansible: inventory и роли

- Инвентори: `ansible/inventories/prod` и `ansible/inventories/stage`.
- Главный playbook: `ansible/playbook.yaml`.
- Основные роли:
  - `ansible/roles/blackbox-exporter` — установка `blackbox-exporter` через Docker Compose.
  - `ansible/roles/monitoring` — конфигурации для Prometheus/Grafana/Alertmanager.
  - `ansible/roles/traefik` — (если используется) развёртывание Traefik.
- Переменные ролей находятся в `defaults/main.yaml` внутри каждой роли.

Запуск с конкретным inventory и лимитом хостов:

```bash
ansible-playbook -i inventories/prod playbook.yaml --limit blackbox-servers
```

## Настройка `blackbox-exporter`

- Шаблон конфигурации для `blackbox-exporter` — `ansible/roles/blackbox-exporter/files/blackbox.yaml`.
- Шаблон docker-compose: `ansible/roles/blackbox-exporter/templates/docker-compose.yaml.j2`.
- Переменные роли (например, порты, пути данных, версии образов) — `ansible/roles/blackbox-exporter/defaults/main.yaml`.

Пример проверки на целевой машине:

```bash
# на целевой машине
docker-compose -f /opt/blackbox/docker-compose.yml up -d
docker-compose -f /opt/blackbox/docker-compose.yml logs -f
```

## Интеграция с Prometheus

- Шаблон scrape конфигурации: `ansible/roles/blackbox-exporter/templates/blackbox-scrape-config.yaml.j2`.
- Дополнительные scrape-конфиги находятся в `ansible/roles/monitoring/files/additional_scrape_configs/blackbox.yaml`.
- Добавьте сгенерированный `blackbox` scrape в основной `prometheus.yml` вашего Prometheus.

## Отладка и проверка

- Проверка доступности экспорта метрик (на локальной машине или в Prometheus server):

```bash
curl -s http://<blackbox_host>:9115/metrics | head -n 50
```

- Если контейнер не запускается: проверьте `docker-compose logs` и `docker ps -a`.
- Для проверки Ansible: используйте `--check` и `--diff`.

## Безопасность

- Никогда не храните секреты в открытом виде в репозитории.
- Используйте `ansible-vault` или секреты облачного провайдера для ключей/паролей.
- Ограничьте сетевой доступ к `blackbox-exporter` и к метрикам Prometheus через firewall/security-groups.

## Варианты кастомизации

- Измените шаблоны в `ansible/roles/blackbox-exporter/templates` для настройки Compose/путей.
- Добавьте дополнительные чекеры/модули в `blackbox.yaml`.
- Расширьте Terraform-модуль `modules/yc-instance` для дополнительных NIC/дисков.

## FAQ и полезные команды

- Синтаксис Ansible playbook:

```bash
ansible-playbook --syntax-check -i inventories/prod playbook.yaml
```

- Dry-run (проверка без изменений):

```bash
ansible-playbook -i inventories/prod playbook.yaml --check
```

- Просмотр Terraform state/outputs:

```bash
terraform show
terraform output
```

## Структура репозитория (подробно)

- `ansible/`
  - `playbook.yaml` — основной playbook
  - `inventories/` — inventory для `prod` и `stage`
  - `roles/` — роли Ansible:
    - `blackbox-exporter/` — role для blackbox
    - `monitoring/` — роли для prometheus/grafana/alertmanager
    - `traefik/` — роль для traefik (опционально)
- `terraform/` — terraform конфигурация и модули
  - `modules/yc-instance/` — пример модуля для инстансов

