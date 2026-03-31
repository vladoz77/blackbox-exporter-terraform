# Terragrunt infrastructure for Yandex Cloud

Каталог `terraform/` содержит Terragrunt-конфигурации для инфраструктуры в Yandex Cloud и генерации inventory для Ansible.

## Что внутри

В проекте используется трёхуровневая схема конфигурации:

* `root.hcl` содержит общие настройки для всех окружений:
  * remote state в Yandex Object Storage
  * генерацию `backend.tf` и `provider.tf`
  * общие input-параметры, такие как `zone`, `platform_id`, `os_name`, `username`
* `prod/prod.hcl` и `stage/stage.hcl` содержат параметры окружения:
  * размер VM
  * настройки boot disk
  * параметры сети
  * имена ресурсов, завязанные на `environment`
* отдельные `terragrunt.hcl` в unit-директориях описывают конкретные модули:
  * `vpc`
  * `blackbox`
  * `monitoring` только в `prod`
  * `inventory`

## Структура каталогов

```text
terraform/
├── root.hcl
├── prod/
│   ├── prod.hcl
│   ├── blackbox/
│   │   └── terragrunt.hcl
│   ├── inventory/
│   │   └── terragrunt.hcl
│   ├── monitoring/
│   │   └── terragrunt.hcl
│   └── vpc/
│       └── terragrunt.hcl
└── stage/
    ├── stage.hcl
    ├── blackbox/
    │   └── terragrunt.hcl
    ├── inventory/
    │   └── terragrunt.hcl
    └── vpc/
        └── terragrunt.hcl
```

## Используемые Terraform-модули

Источник модулей:

```text
https://github.com/vladoz77/terraform-modules
```

Используются следующие модули:

* `yc-network`
* `yc-instance`
* `ansible-inventory`

## Как устроены окружения

### `prod`

Содержит отдельные unit'ы:

* `vpc`
* `blackbox`
* `monitoring`
* `inventory`

Особенности:

* `blackbox` и `monitoring` зависят от `vpc`
* `inventory` зависит от IP-адресов `blackbox` и `monitoring`
* в `prod.hcl` описаны env-specific параметры, включая `static_address`

### `stage`

Содержит unit'ы:

* `vpc`
* `blackbox`
* `inventory`

Особенности:

* `blackbox` зависит от `vpc`
* `inventory` зависит от `blackbox`
* `stage.hcl` хранит env-specific параметры для stage

## Зависимости между unit'ами

Terragrunt строит очередь выполнения по зависимостям:

### `prod`

```text
vpc -> blackbox
vpc -> monitoring
blackbox -> inventory
monitoring -> inventory
```

### `stage`

```text
vpc -> blackbox -> inventory
```

Поэтому при `terragrunt run --all plan` или `terragrunt run --all apply` сначала обрабатывается `vpc`, затем инстансы, затем `inventory`.

## `locals` и `inputs`

В проекте используется следующий паттерн:

* `locals` в Terragrunt нужны для внутренних вычислений и сборки значений
* `inputs` нужны для передачи значений в Terraform-модуль
* env-файлы (`prod.hcl`, `stage.hcl`) подключаются через `read_terragrunt_config(...)`
* в unit-файлах значения окружения обычно используются через:

```hcl
locals {
  stage = read_terragrunt_config(find_in_parent_folders("stage.hcl"))
}
```

или:

```hcl
locals {
  prod = read_terragrunt_config(find_in_parent_folders("prod.hcl"))
}
```

Это позволяет не использовать вложенные `include`, так как Terragrunt поддерживает только один уровень `include`.

## `mock_outputs`

Для зависимостей между unit'ами используются `mock_outputs`, чтобы `init`, `plan` и `validate` могли работать даже тогда, когда upstream unit ещё не был применён.

Пример:

```hcl
dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    subnet_id = "mock-vpc-subnet_id"
  }

  mock_outputs_allowed_terraform_commands = ["plan", "validate", "init"]
}
```

Важно:

* `mock_outputs` не заменяют реальные outputs на `apply`
* реальные значения для dependency появляются после `apply` upstream-модуля и сохраняются в state

## Remote state

Remote state настраивается в [root.hcl](/home/vlad/blackbox-exporter-terraform/terraform/root.hcl):

* backend `s3`
* endpoint `https://storage.yandexcloud.net`
* bucket `vladis-terraform-state`
* ключ state формируется через `path_relative_to_include()`

## Переменные окружения

Перед запуском Terragrunt должны быть заданы:

```bash
export TF_VAR_iam_token=***
export TF_VAR_cloud_id=***
export TF_VAR_folder_id=***
export TF_VAR_ssh_pub_key="ssh-ed25519 AAAA..."
export ACCESS_KEY=***
export SECRET_KEY=***
```

## Основные команды

Пример для `prod`:

```bash
cd terraform/prod
terragrunt run --all init
terragrunt run --all plan
terragrunt run --all apply
```

Пример для `stage`:

```bash
cd terraform/stage
terragrunt run --all init
terragrunt run --all plan
terragrunt run --all apply
```

Запуск отдельного unit:

```bash
cd terraform/stage/vpc
terragrunt init
terragrunt plan
terragrunt apply
```

## Форматирование и проверки

Перед коммитом полезно прогнать:

```bash
terraform fmt -recursive terraform
cd terraform
terragrunt hcl fmt
```

В CI дополнительно проверяются:

* `terraform fmt -check -recursive terraform`
* `terragrunt hcl fmt --check --diff`
* syntax-check для Ansible playbook'ов

## Inventory для Ansible

Модуль `inventory` записывает результат в `ansible/inventories`.

Группы:

* `prod`:
  * `blackbox-server`
  * `monitoring-server`
* `stage`:
  * `monitoring-blackbox-server`
