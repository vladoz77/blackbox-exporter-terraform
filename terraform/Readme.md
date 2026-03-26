# Terragrunt infrastructure for Yandex Cloud

Каталог содержит Terragrunt-конфигурации для развёртывания инфраструктуры в Yandex Cloud и генерации inventory для Ansible.

## Что здесь есть

* `root.hcl` с общими `locals`, backend и provider generation
* окружения `prod` и `stage`
* отдельные модули для `vpc`, `monitoring`, `blackbox` и `inventory`

## Структура

```text
terraform/
├── root.hcl
├── prod/
│   ├── blackbox/
│   ├── inventory/
│   ├── monitoring/
│   └── vpc/
└── stage/
    ├── blackbox/
    ├── inventory/
    └── vpc/
```

## За что отвечает Terraform

* создание VPC и подсети
* создание VM через внешний модуль `yc-instance`
* передача IP-адресов в модуль `ansible-inventory`
* подготовка DNS-записей через `dns_records`
* хранение state в Yandex Object Storage

## Используемые модули

Источник модулей:

```text
https://github.com/vladoz77/terraform-modules
```

Используются:

* `yc-network`
* `yc-instance`
* `ansible-inventory`

## Зависимости

* `blackbox` и `monitoring` зависят от `vpc`
* `inventory` зависит от IP-адресов созданных инстансов
* для `plan`, `validate` и `init` используются `mock_outputs`

## Remote state

Remote state настраивается в [`terraform/root.hcl`](/home/vlad/blackbox-exporter-terraform/terraform/root.hcl):

* backend `s3`
* endpoint `https://storage.yandexcloud.net`
* ключ формируется из `path_relative_to_include()`

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

## Запуск

Из каталога окружения:

```bash
cd terraform/prod
terragrunt run --all init
terragrunt run --all plan
terragrunt run --all apply
```

Для `stage` команды те же, только из `terraform/stage`.

## Inventory для Ansible

Модуль `inventory` записывает результат в `ansible/inventories`:

* `prod` создаёт группы `monitoring-server` и `blackbox-server`
* `stage` создаёт группу `monitoring-blackbox-server`
