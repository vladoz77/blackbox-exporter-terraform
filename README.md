
# Blackbox Exporter — Terraform + Ansible

Инфраструктурный репозиторий для развёртывания Prometheus Blackbox Exporter:
- Terraform — provisioning (инстансы, сеть, security groups).
- Ansible — конфигурация ОС и развёртывание сервисов (Docker Compose).

## Краткий Quick-start

1. Клонируйте репозиторий:

```bash
git clone <repo> && cd blackbox-exporter-terraform
```

2. Terraform (пример prod):

Рекомендуется запускать Terraform из каталога окружения `terraform/environment/<env>`.

```bash
# перейти в каталог окружения
cd terraform/environment/prod

# инициализация
terraform init

# форматирование и валидация
terraform fmt
terraform validate

# план (если в каталоге есть terraform.tfvars, он будет загружен автоматически)
terraform plan

# применение
terraform apply
```

Альтернатива без `cd`:

```bash
terraform -chdir=terraform/environment/prod init
terraform -chdir=terraform/environment/prod plan
```

3. Сгенерированный inventory используйте для Ansible:

```bash
cd ../ansible
ansible-playbook -i inventories/prod playbook.yaml
```

## Что важно знать

- ответственности: Terraform создаёт инфраструктуру и outputs (IP/FQDN), Ansible использует эти outputs для конфигурации и запуска сервисов. Не смешивайте обязанности между инструментами.
- inventory генерируется через `terraform/inventory.tftpl` — если вы меняете имена outputs, обновите шаблон и `ansible/inventories`.


## Полезные файлы

- Основной playbook: `ansible/playbook.yaml`.
- Роль blackbox: `ansible/roles/blackbox-exporter/` (`README.md`, `templates/docker-compose.yaml.j2`, `files/blackbox.yaml`).
- Terraform module for instances: `terraform/modules/yc-instance/` (`README.md`).

## Отладка и полезные команды

```bash
# Terraform
terraform fmt
terraform validate
# перейти в окружение, например:
cd terraform/environment/stage
terraform plan

# Ansible
ansible-playbook --syntax-check -i inventories/prod lackbox-prod.yaml 
ansible-playbook -i inventories/prod/inventory.ini blackbox-prod.yaml --check --diff

# На целевой машине
docker compose -f /path/to/compose/docker-compose.yaml logs -f
curl -s http://<blackbox_host>:9115/metrics | head -n 50
```



