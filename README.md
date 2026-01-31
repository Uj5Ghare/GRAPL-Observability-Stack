# 🎯 GRAPL Observability Stack

> **One stack to watch them all.**  
> Metrics, logs, dashboards, and Slack alerts—on your own servers.

[![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat&logo=docker&logoColor=white)](https://www.docker.com/)
[![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=flat&logo=prometheus&logoColor=white)](https://prometheus.io/)
[![Grafana](https://img.shields.io/badge/Grafana-F46800?style=flat&logo=grafana&logoColor=white)](https://grafana.com/)
[![Loki](https://img.shields.io/badge/Loki-2C3E50?style=flat&logo=grafana&logoColor=white)](https://grafana.com/oss/loki/)

A complete **on-premises monitoring and observability stack**. Collect metrics from your servers, visualize them in dashboards, store and search logs, and get alerts in Slack when something goes wrong—no cloud lock-in.

---

## 👋 New here? Start with this

| If you want to… | Jump to… |
|-----------------|----------|
| Get the stack running in a few minutes | [🚀 Quick Start](#-quick-start) |
| See what’s inside the stack | [📦 What’s Included](#-whats-included) |
| Understand how it all connects | [🏗️ Architecture](#-architecture-overview) |
| Add more servers to monitor | [🖥️ Remote Server Monitoring](#-remote-server-monitoring-node-exporter) |
| Send app logs to Grafana | [📋 Log Aggregation](#-log-aggregation-fluent-bit--loki) |

---

## 📑 Table of Contents

- [📦 What's Included](#-whats-included)
- [🏗️ Architecture Overview](#-architecture-overview)
- [✅ Prerequisites](#-prerequisites)
- [🚀 Quick Start](#-quick-start)
- [⚙️ Configuration](#️-configuration)
- [🖥️ Remote Server Monitoring (Node Exporter)](#-remote-server-monitoring-node-exporter)
- [📋 Log Aggregation (Fluent Bit → Loki)](#-log-aggregation-fluent-bit--loki)
- [🔗 Accessing the Stack](#-accessing-the-stack)
- [📊 Dashboards & Alerts](#-dashboards--alerts)
- [🧹 Maintenance & Cleanup](#-maintenance--cleanup)
- [📋 Summary Checklist](#-summary-checklist)

---

## 📦 What's Included

| Component | What it does | Think of it as… |
|-----------|--------------|------------------|
| **Prometheus** | Collects and stores metrics from your servers | The “metrics database” |
| **Grafana** | Beautiful dashboards and log search | The “control panel” you open in a browser |
| **Loki** | Stores and indexes logs from your apps | “Prometheus, but for logs” |
| **Alertmanager** | Sends alerts to Slack (or other channels) | The “notification router” |
| **Node Exporter** | Exposes CPU, memory, disk per host | The “server health sensor” |
| **cAdvisor** | Exposes container (Docker) metrics | The “container health sensor” |
| **MongoDB Exporter** | Exposes MongoDB metrics | Optional “MongoDB health sensor” |
| **Nginx** | Proxies Grafana, Prometheus, Loki, Alertmanager | The “front door” with friendly URLs |
| **Fluent Bit** *(on remote hosts)* | Sends app logs to Loki | The “log shipper” on each app server |

---

## 🏗️ Architecture Overview

**In one sentence:** Remote servers send **metrics** (via Node Exporter) and **logs** (via Fluent Bit) to your monitoring server; Prometheus and Loki store them; Grafana shows dashboards; Alertmanager sends alerts to Slack.

### Flow diagram (Mermaid)

```mermaid
flowchart LR
    subgraph Remote["🖥️ Remote servers"]
        NE[Node Exporter]
        FB[Fluent Bit]
    end

    subgraph Monitor["🖥️ Your monitoring server"]
        P[Prometheus]
        L[Loki]
        A[Alertmanager]
        G[Grafana]
        N[Nginx]
    end

    SLACK[Slack 💬]

    NE -->|metrics :9100| P
    FB -->|logs :3100| L
    P -->|alerts| A
    A --> SLACK
    P --> G
    L --> G
    N --> G
    N --> P
```

### Simple flow (text)

```
┌─────────────────────────────────────────────────────────────────────┐
│  📡 REMOTE SERVERS (API, DB, Admin, N8N, etc.)                        │
│     Node Exporter (metrics)  ──────┐                                 │
│     Fluent Bit (logs)        ──────┼─────┐                           │
└───────────────────────────────────┼─────┼───────────────────────────┘
                                    │     │
                                    ▼     ▼
┌─────────────────────────────────────────────────────────────────────┐
│  🖥️ MONITORING SERVER (this repo + Docker)                           │
│                                                                      │
│   Prometheus ◄── scrapes metrics  │  Loki ◄── receives logs          │
│         │                         │    │                             │
│         ├──► Alertmanager ────────┼──► Slack                         │
│         │                         │                                   │
│         └──► Grafana ◄────────────┘  (dashboards + log search)        │
│                    ▲                                                  │
│              Nginx (optional: pretty URLs)                            │
└─────────────────────────────────────────────────────────────────────┘
```

---

## ✅ Prerequisites

Before you start, make sure you have:

| Need | What to have |
|------|----------------|
| 🐳 **Docker** | [Docker](https://docs.docker.com/get-docker/) and [Docker Compose](https://docs.docker.com/compose/install/) on the machine that will run the stack |
| 📢 **Slack alerts** *(optional)* | [Slack Incoming Webhooks](https://api.slack.com/messaging/webhooks) for the channels you want alerts in |
| 🔑 **SSH** | Access to any **remote** servers where you’ll install Node Exporter |
| 🍃 **MongoDB** *(optional)* | A MongoDB connection URI if you use the MongoDB Exporter |
| 🌐 **Domains** *(optional)* | DNS for your Grafana/Prometheus URLs (e.g. `grafana.yourdomain.com`) pointing to this server |

---

## 🚀 Quick Start

**Goal:** Run the full stack with one command, then open Grafana.

### Step 1: Get the code

```bash
git clone <this-repo-url> devops-monitoring
cd devops-monitoring
```

*(Or download and extract the repo as a folder.)*

### Step 2: Minimal config (so it runs)

- Open `prometheus/prometheus.yml` and replace every `<on-prem-n8n-ip>`, `<on-prem-api-ip>`, etc., with the **real IP or hostname** of that server (or use `localhost` for a single-machine test).
- *(Optional)* For Slack: create files `alertmanager/slack_url_project0`, `slack_url_project1`, … with your webhook URLs (see [Alertmanager – Slack](#3-alertmanager--slack-notifications)).
- *(Optional)* For MongoDB metrics: set `MONGODB_URI` in `docker-compose.yml` for the `mongo-exporter` service.

### Step 3: Start the stack

```bash
docker compose up -d
```

### Step 4: Open Grafana

- **URL:** http://localhost:3000 (or your server IP and port 3000).
- **Login:** Use the credentials in `grafana/config.monitoring` (keep this file secret in production).

You should see pre-loaded dashboards (e.g. Node Exporter). Prometheus is already configured as a data source.

> 💡 **Tip:** If you only have this one server, the built-in **node-exporter** container already exposes metrics; you’ll see data in the Node Exporter dashboard even before adding remote hosts.

---

## ⚙️ Configuration

### 1️⃣ Prometheus scrape targets

**File:** `prometheus/prometheus.yml`

Replace each placeholder with the **IP or hostname** of the server that runs Node Exporter on port **9100**:

| Placeholder | Server |
|-------------|--------|
| `<on-prem-n8n-ip>` | N8N server |
| `<on-prem-api-ip>` | On-prem API |
| `<on-prem-db-ip>` | On-prem DB |
| `<on-prem-admin-ip>` | On-prem Admin |
| `<remote-api-ip>` | Remote API |
| `<remote-db-ip>` | Remote DB |
| `<remote-admin-ip>` | Remote Admin |

> ⚠️ Each of these hosts must have Node Exporter running and port **9100** open (see [Remote Server Monitoring](#-remote-server-monitoring-node-exporter)).

---

### 2️⃣ MongoDB Exporter *(optional)*

**File:** `docker-compose.yml` → `mongo-exporter` service

If you use the MongoDB Exporter, set your connection string:

```yaml
mongo-exporter:
  environment:
    - MONGODB_URI=mongodb://user:password@host:27017
```

If the exporter runs on another host/port, update the target in `prometheus/prometheus.yml` under `job_name: 'mongodb-exporter'`.

---

### 3️⃣ Alertmanager – Slack notifications

Alerts are routed by **project** (e.g. `project0`, `project1`). Each project uses a Slack webhook stored in a **file**.

1. Create a [Slack Incoming Webhook](https://api.slack.com/messaging/webhooks) for each channel.
2. On the monitoring server, create one file per project (only the URL inside, no extra text):
   - `alertmanager/slack_url_project0`
   - `alertmanager/slack_url_project1`
   - … up to `slack_url_project4`
3. Put the webhook URL in the file, e.g.:
   ```text
   https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX
   ```

Route labels in `alertmanager/config.yml` (e.g. `project0`, `project1`) must match the labels you set in Prometheus.

---

### 4️⃣ Nginx – custom domains *(optional)*

**File:** `nginx/nginx.conf`

To use your own domains (e.g. `grafana.yourdomain.com`):

1. Replace `grafana.ujwal5ghare.xyz`, `prom.ujwal5ghare.xyz`, etc., with **your** domains.
2. Point DNS for those domains to this server’s IP.
3. For HTTPS, add SSL config and certificates (not included in the sample).

---

## 🖥️ Remote Server Monitoring (Node Exporter)

To monitor **other servers** (API, DB, admin, N8N, etc.), install **Node Exporter** on each host so Prometheus can scrape metrics on port **9100**.

### ✅ Install on a remote host

1. Copy to the host:
   - `ssh-file/node_exp_install.sh`
   - `ssh-file/node_exporter.service` (if the script expects it)
2. SSH in and run:
   ```bash
   chmod +x node_exp_install.sh
   ./node_exp_install.sh
   ```
   This downloads Node Exporter, installs it, and sets up a systemd service.
3. **Open port 9100** on that host (firewall / security group).
4. Add that host’s IP to `prometheus/prometheus.yml` in the right job (see [Prometheus scrape targets](#1-prometheus-scrape-targets)).

### ❌ Uninstall Node Exporter

On the remote host:

```bash
sudo bash node_exp_uninstall.sh
```

---

## 📋 Log Aggregation (Fluent Bit → Loki)

Send **application logs** (e.g. from PM2) to Loki so you can search them in Grafana.

1. **Monitoring server:** Loki must be running and reachable (port **3100** or via Nginx).
2. **App server:** Install Fluent Bit and use `ssh-file/fluentbit_setup.sh` (and `ssh-file/fluent-bit.conf` as reference).

When you run `fluentbit_setup.sh`, it asks for:

| Input | Example | Purpose |
|-------|---------|---------|
| **Log filename** | `index`, `remote-admin` | PM2 log: `~/.pm2/logs/<name>-out.log` and `-error.log` |
| **Environment** | `staging`, `prod` | Loki label `env` |
| **Service name** | `dilicut-admin`, `remote` | Loki label `service` |

Before running:

- Set the **Loki host and port** in the script/config to your monitoring server (e.g. IP and `3100`).
- Ensure the app server can reach that host/port (firewall/security group).

After setup, query logs in Grafana via **Explore** and the Loki data source.

---

## 🔗 Accessing the Stack

| Service | With Nginx (custom domains) | Direct (no Nginx) |
|---------|-----------------------------|--------------------|
| **Grafana** | http://grafana.yourdomain.com | http://\<server-ip\>:3000 |
| **Prometheus** | http://prom.yourdomain.com | http://\<server-ip\>:9090 |
| **Loki** | http://loki.yourdomain.com | http://\<server-ip\>:3100 |
| **Alertmanager** | http://alerts.yourdomain.com | http://\<server-ip\>:9093 |

---

## 📊 Dashboards & Alerts

### 📊 Dashboards (Grafana)

Pre-provisioned dashboards (from `grafana/provisioning/dashboards/`):

| Dashboard | What it shows |
|-----------|----------------|
| **Node Exporter Full** | CPU, memory, disk, network per host |
| **K8s-*** (Pods, Nodes, Cluster, API Server, Global) | Kubernetes-oriented views |
| **MongoDB Profiler** | MongoDB metrics (when MongoDB Exporter is used) |
| **Athena** | For Athena data source (if configured) |

The Prometheus data source is provisioned via `grafana/provisioning/datasources/datasource.yml`.

### 🚨 Alerts (Prometheus + Alertmanager)

Rules live in `prometheus/alertmanager.yml`. Examples:

| Alert | When it fires |
|-------|----------------|
| **InstanceDown** | Target unreachable for 5 minutes |
| **HighCPUUsage** | CPU > 90% for 5 minutes |
| **HighMemoryUsage** | Memory > 90% for 5 minutes |
| **HighSwapUsage** | Swap > 95% for 5 minutes |
| **HighDiskIOUsage** | Disk I/O > 85% for 5 minutes |
| **DiskSpaceRunningOut** | Root filesystem > 95% for 5 minutes |

Alertmanager routes them to Slack by project (see [Alertmanager – Slack](#3-alertmanager--slack-notifications)).

---

## 🧹 Maintenance & Cleanup

| Action | Command |
|--------|---------|
| **Restart stack** | `docker compose restart` |
| **Stop stack** | `docker compose down` (add `-v` only if you want to **delete** volume data) |
| **View logs** | `docker compose logs -f` or `docker compose logs -f prometheus` |
| **Uninstall Node Exporter** (on remote host) | `sudo bash ssh-file/node_exp_uninstall.sh` |
| **Uninstall Prometheus** (on a host where you ran it manually) | Use `ssh-file/prometheus_uninstall.sh` if available |

---

## 📋 Summary Checklist

Use this before you say “done”:

- [ ] Docker and Docker Compose installed
- [ ] All `<...>` placeholders in `prometheus/prometheus.yml` replaced with real IPs/hostnames
- [ ] Node Exporter installed on every host you want to monitor (port 9100 open)
- [ ] Slack webhook files under `alertmanager/` if you use Slack alerts
- [ ] `MONGODB_URI` set in `docker-compose.yml` if using MongoDB Exporter
- [ ] Nginx server names updated in `nginx/nginx.conf` if using custom domains
- [ ] `docker compose up -d` run and all containers healthy
- [ ] Grafana login works; Prometheus (and Loki) datasources available
- [ ] *(Optional)* Fluent Bit on app servers sending logs to Loki

---

## 📚 Learn more

- [Prometheus](https://prometheus.io/docs/) · [Grafana](https://grafana.com/docs/) · [Loki](https://grafana.com/docs/loki/) · [Alertmanager](https://prometheus.io/docs/alerting/latest/alertmanager/)
