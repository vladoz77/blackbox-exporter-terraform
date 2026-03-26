# Infrastructure as Code: Terraform + Ansible

Репозиторий объединяет два слоя автоматизации:

* `terraform/` поднимает инфраструктуру в Yandex Cloud через Terragrunt
* `ansible/` настраивает хосты и разворачивает сервисы

В текущем виде проект покрывает:

* окружения `stage` и `prod`
* monitoring-стек на базе VictoriaMetrics, VMAlert, Alertmanager и Grafana
* Blackbox Exporter
* Traefik как edge reverse proxy
* Grafana Alloy для сбора и отправки telemetry

## Структура

```text
.
├── terraform/   # Инфраструктура и генерация inventory
├── ansible/     # Playbook'и, inventories и роли
└── README.md
```

## Как устроен поток

```text
Terragrunt/Terraform
        ↓
  VPC / VM / DNS / inventory
        ↓
      Ansible
        ↓
 common / docker / monitoring / traefik / alloy / blackbox
```

## Окружения

* `prod`:
  * отдельный monitoring-сервер
  * отдельный blackbox-сервер
* `stage`:
  * monitoring, blackbox, traefik и alloy запускаются на одном сервере

## Terraform

Каталог [`terraform/Readme.md`](/home/vlad/blackbox-exporter-terraform/terraform/Readme.md) описывает структуру Terragrunt-окружений и зависимости между модулями.

Сейчас Terraform-часть отвечает за:

* VPC и подсеть
* VM для `monitoring` и `blackbox`
* DNS records через входы модулей
* генерацию Ansible inventory в `ansible/inventories`
* remote state в Yandex Object Storage

Быстрый старт:

```bash
cd terraform/prod
terragrunt run --all init
terragrunt run --all plan
terragrunt run --all apply
```

## Ansible

Каталог [`ansible/Readme.md`](/home/vlad/blackbox-exporter-terraform/ansible/Readme.md) содержит детали по playbook'ам, inventory и ролям.

Основные playbook'и:

* `ansible/blackbox-prod.yaml`
* `ansible/blackbox-stage.yaml`

Используемые роли:

* `common`
* `docker`
* `monitoring`
* `grafana-alloy`
* `blackbox-exporter`
* `traefik`

Применение:

```bash
cd ansible
ansible-playbook -i inventories/prod/inventory.ini blackbox-prod.yaml
ansible-playbook -i inventories/stage blackbox-stage.yaml
```

## Примечания

* Terraform создаёт инфраструктуру и inventory, но не конфигурирует сервисы
* Ansible не управляет облачными ресурсами, а настраивает уже созданные хосты
* README внутри ролей описывают реальные defaults, шаблоны и поведение ролей на текущий момент
