# Monitoring Stack (VictoriaMetrics + Grafana + Alertmanager)

**Ansible role** for deploying a complete monitoring stack using:

* **VictoriaMetrics** — time series database
* **vmalert** — alert evaluation engine
* **Alertmanager** — alert routing
* **Grafana** — dashboards & visualization
* **Traefik** — external ingress / reverse proxy

The stack is deployed via **Docker Compose v2** and designed to be:

* reproducible
* idempotent
* easy to extend
* suitable for production

---

## 📐 Architecture

```text
                +-------------+
                |   Traefik   |
                +------+------+
                       |
    ------------------------------------------------
    |              |               |              |
+---v---+      +---v---+       +---v---+      +---v---+
|  VM   |      | vmalert|       |  AM   |      |Grafana|
| 8428  |      |  8880  |       | 9093  |      | 3000  |
+-------+      +--------+       +--------+      +-------+
```

All services are connected to a shared **external Docker network**.

---

## 🚀 Features

* ✔️ VictoriaMetrics with dynamic scrape configs
* ✔️ vmalert with file-based alert rules
* ✔️ Alertmanager ready for Slack / Telegram / Webhooks
* ✔️ Grafana auto-provisioning (datasources & dashboards)
* ✔️ Traefik labels for HTTPS exposure
* ✔️ Health checks and service ordering
* ✔️ Fully configurable via variables

---

## 📦 Requirements

### Control Node

* Ansible **>= 2.15**
* Install required collections:

  ```bash
  ansible-galaxy collection install -r requirements.yaml
  ```

### Managed Host

* Docker **>= 24**
* Docker Compose v2 (`docker compose`)
* Existing Docker network (default: `monitoring_network`)
* Traefik configured with:

  * entrypoint `websecure`
  * certResolver `le`

---

## ⚙️ Role Variables

### Global

| Variable               | Default                           | Description             |
| ---------------------- | --------------------------------- | ----------------------- |
| `work_dir`             | `/home/{{ username }}/monitoring` | Base directory          |
| `docker_network_name`  | `monitoring_network`              | External Docker network |
| `default_metrics_path` | `metrics`                         | Metrics endpoint        |

---

### VictoriaMetrics

| Variable                  | Default         |
| ------------------------- | --------------- |
| `victoriametrics_enable`  | `true`          |
| `victoriametrics_version` | `v1.118.0`      |
| `victoriametrics_port`    | `8428`          |
| `victoriametrics_url`     | `vm.home.local` |
| `scrape_interval`         | `10s`           |

---

### vmalert

| Variable          | Default              |
| ----------------- | -------------------- |
| `vmalert_enable`  | `true`               |
| `vmalert_version` | `v1.118.0`           |
| `vmalert_port`    | `8880`               |
| `vmalert_url`     | `vmalert.home.local` |

---

### Alertmanager

| Variable               | Default                   |
| ---------------------- | ------------------------- |
| `alertmanager_enable`  | `true`                    |
| `alertmanager_version` | `v0.28.0`                 |
| `alertmanager_port`    | `9093`                    |
| `alertmanager_url`     | `alertmanager.home.local` |

---

### Grafana

| Variable          | Default              |
| ----------------- | -------------------- |
| `grafana_enable`  | `true`               |
| `grafana_version` | `11.5.0`             |
| `grafana_port`    | `3000`               |
| `grafana_url`     | `grafana.home.local` |

---

## 🗂️ Directory Structure

```text
monitoring/
├── victoriametrics/
│   ├── docker-compose.yaml
│   ├── scrape.yaml
│   └── jobs/
├── vmalert/
│   ├── docker-compose.yaml
│   └── rules/
├── alertmanager/
│   ├── docker-compose.yaml
│   └── alertmanager.yaml
└── grafana/
    ├── docker-compose.yaml
    ├── dashboards.yaml
    ├── datasources.yaml
    └── dashboards/
```

---

## 🔍 Scrape Configuration

Add additional scrape jobs to:

```text
files/additional_scrape_configs/*.yaml
```

They will be mounted into VictoriaMetrics:

```text
/etc/prometheus/jobs/
```

and loaded automatically.

---

## 📈 Grafana Provisioning

Grafana is fully provisioned using file-based configuration:

* Datasources
* Dashboards

### Dashboards

Stored in:

```text
files/dashboards/
```

and updated automatically.

---

## 🚨 Alerting

### vmalert Rules

```text
files/rules/*.yaml
```

Mounted into:

```text
/etc/alerts/
```

### Alertmanager

By default, Alertmanager uses a **blackhole receiver**.

For production, configure:

* Slack
* Telegram
* Email
* Webhooks

Template:

```text
templates/alertmanager.yaml.j2
```

---

## ▶️ Usage

```yaml
- hosts: monitoring
  become: true
  roles:
    - monitoring
```

Run:

```bash
ansible-playbook site.yaml
```

---

## 🏷️ Tags

Run individual components:

```bash
ansible-playbook site.yaml --tags grafana
ansible-playbook site.yaml --tags victoriametrics
ansible-playbook site.yaml --tags alertmanager
```

---

## 📝 Notes & Best Practices

* Do not expose container ports when using Traefik
* Ensure the Docker network exists:

  ```bash
  docker network create monitoring_network
  ```
* For production environments:

  * use external volumes
  * configure Alertmanager receivers
  * enable authentication in Grafana

---

