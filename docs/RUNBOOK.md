# CloudOpsHub Deployment Runbook

> A step-by-step guide to deploy TheEpicBook application from scratch.

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Create Cloud Infrastructure with Terraform](#2-create-cloud-infrastructure-with-terraform)
3. [Add Secrets to GitHub](#3-add-secrets-to-github)
4. [Deploy the Application](#4-deploy-the-application)
5. [Set Up Monitoring](#5-set-up-monitoring)
6. [Useful Commands](#6-useful-commands)
7. [Troubleshooting](#7-troubleshooting)

---

## 1. Prerequisites

| Tool | Install Link |
|------|-------------|
| **Terraform** >= 1.5 | [Install Terraform](https://www.terraform.io/downloads) |
| **Docker** & Docker Compose | [Install Docker](https://docs.docker.com/get-docker/) |
| **gcloud CLI** | [Install gcloud](https://cloud.google.com/sdk/docs/install) |

### Accounts needed

- **Google Cloud** account with a project (ours is `expadox-lab`)
- **GitHub** account with access to this repo
- **Snyk** account (free tier) for security scanning
- **SonarCloud** account for code quality scanning

---

## 2. Create Cloud Infrastructure with Terraform

```bash
cd terraform

# Initialize
terraform init

# Deploy dev environment
terraform plan -var-file=envs/dev.tfvars
terraform apply -var-file=envs/dev.tfvars
```

### What Terraform creates

- **VPC & Network** — Private network with subnets, NAT gateway, firewall rules
- **Compute Engine VM** — Container-Optimized OS with Docker pre-installed
- **Artifact Registry** — Docker container registry on GCP
- **Load Balancer** — Global HTTP load balancer with health check
- **Secret Manager** — Stores database URL and Grafana password
- **Workload Identity Federation** — Keyless GitHub Actions auth to GCP
- **Monitoring** — Uptime checks and alert policies

### Save the outputs

```bash
terraform output load_balancer_ip
terraform output service_account_email
terraform output wif_provider
terraform output artifact_registry_url
```

---

## 3. Add Secrets to GitHub

Go to **Settings > Secrets and variables > Actions** and add:

| Secret | Value |
|--------|-------|
| `GCP_PROJECT_ID` | `expadox-lab` |
| `GCP_REGION` | `us-central1` |
| `GCP_SA_EMAIL` | From `terraform output service_account_email` |
| `GCP_WIF_PROVIDER` | From `terraform output wif_provider` |
| `SNYK_TOKEN` | From [snyk.io/account](https://snyk.io/account) |
| `SONAR_TOKEN` | From [sonarcloud.io/account/security](https://sonarcloud.io/account/security) |
| `SONAR_HOST_URL` | `https://sonarcloud.io` |

See [GITHUB_SECRETS.md](GITHUB_SECRETS.md) for details.

---

## 4. Deploy the Application

### Option A: GitOps Deploy (standard flow)

1. Push code to `main`
2. **CI pipeline** runs: lint, security scans, build Docker images, push to Artifact Registry
3. **CD pipeline** runs: Terraform scans, verify images, update GitOps manifests
4. **GitOps sync agent** on VM detects changes and auto-deploys within 60s

### Option B: Local Development

```bash
cp .env.example .env
# Edit .env with your values
docker compose up
# Open http://localhost
```

With local database:
```bash
docker compose --profile local up
```

### Option C: Manual Deploy to GCP

```bash
gcloud compute ssh cloudopshub-app-dev --zone=us-central1-a --project=expadox-lab --tunnel-through-iap

# On the VM:
cd /var/lib/gitops/repo
sudo HOME=/var/lib /var/lib/toolbox/docker-compose \
  --env-file /var/lib/cloudopshub/.env \
  -f gitops/base/docker-compose.yml up -d
```

---

## 5. Set Up Monitoring

Monitoring services (Prometheus, Grafana, Alertmanager, Node Exporter) are defined in the GitOps compose file. Once enabled:

| Tool | URL | Login |
|------|-----|-------|
| **Prometheus** | http://VM_IP:9090 | No login |
| **Grafana** | http://VM_IP:3000 | admin / `$GRAFANA_PASSWORD` |
| **Alertmanager** | http://VM_IP:9093 | No login |

---

## 6. Useful Commands

### Docker

```bash
docker compose ps              # Running containers
docker compose logs -f backend # Follow backend logs
docker compose restart backend # Restart a service
docker compose down            # Stop everything
```

### Terraform

```bash
terraform plan -var-file=envs/dev.tfvars    # Preview changes
terraform apply -var-file=envs/dev.tfvars   # Apply changes
terraform destroy -var-file=envs/dev.tfvars # Destroy (careful!)
```

### GCP

```bash
gcloud compute instances list --project=expadox-lab
gcloud compute ssh cloudopshub-app-dev --zone=us-central1-a --project=expadox-lab --tunnel-through-iap
```

---

## 7. Troubleshooting

### Backend "Access Denied" on database
- Check `.env` file has correct `DB_PASSWORD` and `DATABASE_URL`
- Verify database container is healthy: `docker compose ps`

### "Unauthenticated request" on Artifact Registry
- Docker auth token expired — re-run the token refresh on the VM
- Check `/var/lib/.docker/config.json` exists and is valid

### Terraform "Error acquiring state lock"
```bash
terraform force-unlock <LOCK_ID>
```

### App shows "502 Bad Gateway"
- Backend may still be starting — wait 10-20 seconds
- Check backend logs: `docker compose logs backend`

### GitOps agent not deploying
- Check sync agent logs: `sudo docker logs gitops-sync --tail 20`
- Verify it can reach GitHub and Artifact Registry
