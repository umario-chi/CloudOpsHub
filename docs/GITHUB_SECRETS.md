# GitHub Actions Secrets Configuration

All secrets must be configured in **Settings > Secrets and variables > Actions** in your GitHub repository.

## Required Secrets

### AWS (ECR Registry)

| Secret | Description | Example |
|--------|-------------|---------|
| `AWS_ACCOUNT_ID` | AWS account ID for ECR | `123456789012` |
| `AWS_REGION` | AWS region where ECR repos live | `us-east-1` |
| `AWS_ACCESS_KEY_ID` | IAM user access key with ECR permissions | `AKIA...` |
| `AWS_SECRET_ACCESS_KEY` | IAM user secret key | `wJalr...` |

### Security Scanning

| Secret | Description | How to Get |
|--------|-------------|------------|
| `SNYK_TOKEN` | Snyk API token for vulnerability scanning | [snyk.io/account](https://snyk.io/account) |
| `SONAR_TOKEN` | SonarQube authentication token | SonarQube > My Account > Security |
| `SONAR_HOST_URL` | SonarQube server URL | `https://sonarqube.example.com` |

### HashiCorp Vault

| Secret | Description |
|--------|-------------|
| `VAULT_ADDR` | Vault server URL (e.g., `https://vault.example.com`) |
| `VAULT_ROLE_ID` | AppRole role ID for authentication |
| `VAULT_SECRET_ID` | AppRole secret ID for authentication |

Vault must have these paths configured:
- `secret/data/cloudopshub/database` with key `DATABASE_URL`
- `secret/data/cloudopshub/argocd` with key `ARGOCD_AUTH_TOKEN`

### ArgoCD

| Secret | Description |
|--------|-------------|
| `ARGOCD_SERVER` | ArgoCD server URL (e.g., `https://argocd.example.com`) |

### Automatic (no setup needed)

| Secret | Description |
|--------|-------------|
| `GITHUB_TOKEN` | Provided automatically by GitHub Actions |
