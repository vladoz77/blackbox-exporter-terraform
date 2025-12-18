# blackbox-exporter (Terraform)

**Кратко:** Terraform-конфигурация для развёртывания виртуальной машины в Yandex Cloud с сетью, подсетью, security group, DNS-записью и выводом IP/ID/имени DNS — предназначена для размещения blackbox-exporter (сам экспортер не устанавливается автоматически).

---

## 🔧 Что создаётся

- VPC-сеть (`yandex_vpc_network`)
- Subnet (`yandex_vpc_subnet`)
- Две security groups (`ssh-access`, `blackbox-exporter-access`) — открыты порты 22 и 9115
- Виртуальная машина `yandex_compute_instance.vm` (с публичным NAT IP)
- DNS-запись (`yandex_dns_recordset`) в зоне `home-local-zone`

---

## ✅ Требования

- Terraform >= **1.9.8**
- Yandex Cloud аккаунт
- S3-бакет для хранения состояния (настроен backend `s3` для Yandex Object Storage — см. `main.tf`)
- Значения для переменных: `iam_token`, `cloud_id`, `folder_id`, `ssh_pub_key`, `dns`, и т. д.

---

## 🗂 Файлы в репозитории

- `main.tf` — провайдер и ресурс виртуальной машины
- `network.tf` — сеть, подсеть, DNS запись
- `security_groups.tf` — правила доступа
- `variables.tf` — все переменные
- `terraform.tfvars` — пример значений переменных
- `data.tf` — поиск зоны DNS
- `output.tf` — выводы (IP, ID, DNS)

---

## ⚙️ Настройка переменных

Можно задать переменные через `terraform.tfvars` (в репозитории уже есть пример) или через переменные окружения `TF_VAR_<name>`. Обязательные переменные:

- `iam_token` — IAM токен Yandex Cloud
- `cloud_id` — Cloud ID
- `folder_id` — Folder ID
- `ssh_pub_key` — открытый SSH ключ
- `dns` — объект с `record_name`, `type` и `ttl`

Пример (в `terraform.tfvars`):

```hcl
iam_token = "..."
cloud_id  = "..."
folder_id = "..."
ssh_pub_key = "ssh-rsa AAAA..."

# dns:
# dns = {
#   record_name = "blackbox.home-local.site."
#   ttl = 300
#   type = "A"
# }
```

---

## 🚀 Быстрый старт

1. Инициализация:

```bash
terraform init
```

2. Предпросмотр:

```bash
terraform plan -out plan.tfplan
```

3. Применение:

```bash
terraform apply "plan.tfplan"
```

4. Удаление ресурсов:

```bash
terraform destroy
```

Просмотреть выводы можно командой:

```bash
terraform output
```

SSH на созданную машину:

```bash
ssh ubuntu@$(terraform output -raw blackbox_external_ip)
```

---

