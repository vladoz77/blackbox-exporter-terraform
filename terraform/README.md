# Terraform — Blackbox Exporter infra

Кратко: в этом каталоге находится инфраструктурный код Terraform, который создаёт виртуальные машины и сети для развёртывания `blackbox-exporter` и генерирует inventory для Ansible.

**Что делает**
- Создаёт инстансы и сетевые ресурсы (модуль `modules/yc-instance` используется как пример для Yandex Cloud).
- Экспортирует output-значения (IP/FQDN), которые используются для рендеринга Ansible inventory через `terraform/inventory.tftpl`.

**Требования**
- `terraform` >= 1.0
- Провайдер: `yandex` (настройте credentials для доступа к Yandex Cloud)

Быстрый старт

Рекомендуется запускать Terraform из каталога окружения `terraform/environment/<env>` (там лежат `main.tf`, `variables.tf` и `terraform.tfvars`).

1. Перейдите в нужное окружение (пример `stage`):

```bash
cd terraform/environment/stage
```

2. Инициализация (обязательно при первом запуске или после изменений провайдеров):

```bash
terraform init
```

3. Рекомендуемые проверки и запуск плана:

```bash
terraform fmt
terraform validate
terraform plan          # если в каталоге есть terraform.tfvars, он загрузится автоматически
# или явно
terraform plan -var-file=terraform.tfvars
```

4. Применение:

```bash
terraform apply         # или: terraform apply -var-file=terraform.tfvars
```

Альтернатива без `cd`: используйте `-chdir` (Terraform >= 0.15):

```bash
terraform -chdir=terraform/environment/stage init
terraform -chdir=terraform/environment/stage plan
```

После `apply` получите outputs для генерации inventory:

```bash
terraform output
```

Важные файлы и шаблоны
-- `environment/` — каталоги `prod` и `stage`, в каждом есть `terraform.tfvars` с переменными окружения.
- `inventory.tftpl` — шаблон для генерации Ansible inventory на основе outputs.
- `modules/yc-instance/` — модуль создания инстанса в Yandex Cloud (см. `README.md` внутри модуля).
- `output.tf` — перечислены outputs, которые критичны для Ansible (IP, fqdn, теги).

Переменные и рекомендации
- Если в каталоге расположен `terraform.tfvars`, Terraform загрузит его автоматически при запуске в этом каталоге.
- Используйте `-var-file` когда требуется явно выбрать другой файл (например `terraform plan -var-file=prod.tfvars`).
- Обязательные переменные: `zone`, `boot_disk.image_id` (проверяйте `variables.tf`).
- Для SSH доступа передавайте публичный ключ в переменную `ssh` (обычно `file("~/.ssh/id_rsa.pub")`).

Как генерируется inventory
- После `terraform apply` шаблон `terraform/inventory.tftpl` рендерится в Ansible inventory используя outputs. Не меняйте имена output-переменных без одновременного обновления шаблона и `ansible/inventories`.

