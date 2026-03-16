# CloudOpsHub Project Progress

> Last updated: 2026-03-16
> Reference: Project.md for full requirements

## ✅ Completed

### A. Environment Setup (Terraform)
- [x] Terraform modules: network, compute, storage, secrets, monitoring, load_balancer, wif
- [x] GCP APIs enabled (compute, storage, secretmanager, iam, iamcredentials, sts, etc.)
- [x] VPC, subnet, firewall rules, NAT, router
- [x] GCE VM instance (e2-medium, COS image) with startup script
- [x] Load balancer (global HTTP LB with health check)
- [x] Artifact Registry (Docker) for container images
- [x] Static assets GCS bucket
- [x] Secret Manager (database_url, grafana_password)
- [x] Monitoring: alert policies (CPU, DB, uptime), notification channel, uptime check, logging metric
- [x] Workload Identity Federation (WIF) module for keyless GitHub Actions auth
- [x] Terraform state bucket (GCS)
- [x] **Infrastructure currently DESTROYED** — run `terraform apply` to recreate

### B. Dockerization
- [x] Backend Dockerfile: `theepicbook/Dockerfile`
- [x] Frontend Dockerfile: `nginx/Dockerfile`
- [x] Database Dockerfile: `theepicbook/db/Dockerfile`

### C. CI/CD Pipeline
- [x] CI workflow: `.github/workflows/ci.yml`
  - Snyk code scan, SonarQube scan, Gitleaks, ESLint, Hadolint
  - Docker build (backend, frontend, database)
  - Trivy image scanning
  - Push to Artifact Registry
- [x] CD workflow: `.github/workflows/cd.yml`
  - Checkov + TFSec Terraform scanning
  - WIF auth to GCP
  - Verify images in Artifact Registry
  - Vault secret fetching
  - GitOps manifest update + ArgoCD sync
- [x] Fixed cd.yml: added `id-token: write` permission for WIF

### D. Infrastructure as Code
- [x] Full Terraform config with modules
- [x] Multi-environment support (dev/staging/production tfvars)
- [x] Deterministic naming — GitHub secrets survive destroy/apply cycles

### E. GitOps with ArgoCD
- [ ] Create `gitops/` directory structure (gitops/base/docker-compose.yml)
- [ ] Install ArgoCD on VM
- [ ] Configure ArgoCD to watch Git repo

### F. Monitoring, Logging, and Alerts
- [x] Prometheus + Grafana in VM startup script
- [x] GCP Cloud Monitoring alert policies
- [x] Grafana dashboard JSON
- [ ] Verify monitoring stack runs on VM after `terraform apply`

## 🔲 Not Started / In Progress

### GitHub Secrets to Add (do FIRST)
| Secret | Value | Added? |
|---|---|---|
| `GCP_PROJECT_ID` | `expandox-project1` | ⬜ |
| `GCP_REGION` | `us-central1` | ⬜ |
| `GCP_SA_EMAIL` | `cloudopshub-app-dev@expandox-project1.iam.gserviceaccount.com` | ⬜ |
| `GCP_WIF_PROVIDER` | `projects/663255337358/locations/global/workloadIdentityPools/cloudopshub-github-dev/providers/github-provider` | ⬜ |
| `SNYK_TOKEN` | *(from snyk.io)* | ⬜ |
| `SONAR_TOKEN` | *(from sonarcloud.io)* | ⬜ |
| `SONAR_HOST_URL` | *(SonarQube/SonarCloud URL)* | ⬜ |
| `VAULT_ADDR` | *(Vault server URL)* | ⬜ |
| `VAULT_ROLE_ID` | *(from Vault)* | ⬜ |
| `VAULT_SECRET_ID` | *(from Vault)* | ⬜ |
| `ARGOCD_SERVER` | *(ArgoCD URL on VM)* | ⬜ |

### Remaining Tasks (in order)
1. ⬜ Add 4 GCP secrets to GitHub
2. ⬜ Set up Snyk account → add SNYK_TOKEN
3. ⬜ Set up SonarCloud/SonarQube → add SONAR_TOKEN, SONAR_HOST_URL
4. ⬜ Create `gitops/` directory structure
5. ⬜ `terraform apply` to recreate infrastructure
6. ⬜ Install & configure HashiCorp Vault on VM → add VAULT secrets
7. ⬜ Install & configure ArgoCD on VM → add ARGOCD_SERVER
8. ⬜ Verify monitoring stack (Prometheus + Grafana) on VM
9. ⬜ End-to-end test: push code → CI builds → CD deploys via ArgoCD
10. ⬜ Set up staging environment

## 📝 Key Values (deterministic, survive destroy/apply)
- **Project ID:** expandox-project1
- **Project Number:** 663255337358
- **Region:** us-central1
- **SA Email:** cloudopshub-app-dev@expandox-project1.iam.gserviceaccount.com
- **WIF Provider:** projects/663255337358/locations/global/workloadIdentityPools/cloudopshub-github-dev/providers/github-provider
- **Artifact Registry:** us-central1-docker.pkg.dev/expandox-project1/cloudopshub-docker
- **GitHub Repo:** lakunzy7/CloudOpsHub
