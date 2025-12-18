
# 🐳 Ansible Role: `docker`

Устанавливает и настраивает **Docker CE** на системах **Ubuntu** и **RHEL/CentOS**.  
Автоматически добавляет пользователя, от которого запущен плейбук, в группу `docker` и создаёт указанную Docker-сеть.

> ✅ Подходит для использоания в CI/CD, Jenkins-агентов, серверов с Traefik и других production-сценариев.

---

## ✅ Поддерживаемые ОС

| Семейство | Поддерживаемые дистрибутивы |
|----------|-----------------------------|
| Debian   | Ubuntu 20.04, 22.04, 24.04 |
| RedHat   | CentOS 8, Rocky Linux 8/9, RHEL 8/9 |

---

## 🧩 Структура роли

```
roles/docker/
├── defaults/
│   └── main.yaml
├── handlers/
│   └── main.yaml
├── tasks/
│   ├── main.yaml
│   ├── rhel.yaml
│   └── ubuntu.yaml
└── vars/
    ├── rhel.yaml
    └── ubuntu.yaml
```

---

## ⚙️ Переменные по умолчанию

Файл: `defaults/main.yaml`

```yaml
docker_network_name: "default"  # Имя Docker-сети, которая будет создана
```

> Пользователь определяется автоматически через `ansible_user`.

---

## 📦 Переменные для Ubuntu (`vars/ubuntu.yaml`)

```yaml
docker_repo: "deb [arch=amd64] https://download.docker.com/linux/ubuntu {{ ansible_distribution_release }} stable"
docker_gpg_key: "https://download.docker.com/linux/ubuntu/gpg"

packages:
  - docker-ce
  - docker-ce-cli
  - containerd.io
  - docker-buildx-plugin
  - docker-compose-plugin

docker_service_name: "docker.service"
```

---

## 📦 Переменные для RHEL (`vars/rhel.yaml`)

```yaml
repo_url: "https://download.docker.com/linux/centos/docker-ce.repo"
repo_dest: "/etc/yum.repos.d/docker-ce.repo"

packages:
  - dnf-plugins-core
  - docker-ce
  - docker-ce-cli
  - containerd.io
  - docker-buildx-plugin
  - docker-compose-plugin

docker_service_name: "docker.service"
```

---

## 🔁 Handlers

| Handler | Действие |
|--------|---------|
| `started_docker` | Запускает и включает службу `docker.service` после установки |

> Вызывается через `notify` после установки пакетов.

---

## 🧪 Зависимости

- Ansible `>= 2.10`
- Коллекция: `community.docker` (для `docker_network`)

Установка:
```bash
ansible-galaxy collection install community.docker
```

---

## 🚀 Использование

### 1. Включить роль в плейбук

```yaml
- hosts: jenkins-server
  become: yes
  roles:
    - role: docker
      docker_network_name: "traefik-network"
```

### 2. Или вручную (с переменными)

```yaml
- name: Install Docker
  ansible.builtin.include_role:
    name: docker
  vars:
    docker_network_name: "traefik-network"
```

---

## 👤 Как определяется пользователь?

Роль **автоматически использует пользователя**, от которого запущен Ansible:

```yaml
name: "{{ ansible_user | default(ansible_ssh_user | default('ubuntu')) }}"
```

➡️ Это значит:
- Если Ansible подключается как `ubuntu` → он будет добавлен в группу `docker`
- Если как `jenkins` → добавится `jenkins`
- Если имя не определено → по умолчанию `ubuntu`

> ✅ Никакого хардкода — роль сама адаптируется под контекст.

---

## ✅ Проверка после установки

```bash
# Проверь, что Docker установлен
docker --version

# Проверь, что пользователь в группе docker
groups {{ ansible_user }}

# Проверь, что сеть создана
docker network ls | grep traefik-network
```

---

## 🛠 Пример `group_vars`

```yaml
# group_vars/jenkins-server.yml
docker_network_name: "traefik-network"
```

---

## 📚 Ссылки

- [Официальная документация Docker](https://docs.docker.com/engine/install/)
- [Ansible Collection: community.docker](https://galaxy.ansible.com/community/docker)

---

> ✅ Роль протестирована, модульна и готова к использованию в production.  
> Поддерживает автоматическое определение пользователя, кроссплатформенность и интеграцию с Jenkins, Nexus, Traefik.

---

