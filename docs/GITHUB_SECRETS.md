# GitHub Actions Secrets Configuration

All secrets must be configured in **Settings > Secrets and variables > Actions** in your GitHub repository.

## Required Secrets

### GCP (Workload Identity Federation)

| Secret | Description | Example |
|--------|-------------|---------|
| `GCP_PROJECT_ID` | GCP project ID | `expadox-lab` |
| `GCP_REGION` | GCP region | `us-central1` |
| `GCP_SA_EMAIL` | Service account email for WIF | `cloudopshub-app-dev@expadox-lab.iam.gserviceaccount.com` |
| `GCP_WIF_PROVIDER` | Workload Identity Federation provider | `projects/129303118923/locations/global/workloadIdentityPools/cloudopshub-github-dev/providers/github-provider` |

### Security Scanning

| Secret | Description | How to Get |
|--------|-------------|------------|
| `SNYK_TOKEN` | Snyk API token for vulnerability scanning | [snyk.io/account](https://snyk.io/account) |
| `SONAR_TOKEN` | SonarCloud authentication token | [sonarcloud.io/account/security](https://sonarcloud.io/account/security) |
| `SONAR_HOST_URL` | SonarCloud URL | `https://sonarcloud.io` |

### Automatic (no setup needed)

| Secret | Description |
|--------|-------------|
| `GITHUB_TOKEN` | Provided automatically by GitHub Actions |
