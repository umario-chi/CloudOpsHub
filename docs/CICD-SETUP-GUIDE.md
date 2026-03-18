# CI/CD Pipeline Setup Guide - CloudOpsHub

This guide walks you through setting up every secret and service needed for the CI/CD pipelines.

---

## 1. Overview

### CI Pipeline (`.github/workflows/ci.yml`) — Triggered on push/PR to `main`:
- Snyk vulnerability scan
- SonarCloud code quality scan
- Gitleaks secret detection
- ESLint + Hadolint linting
- Docker build + Trivy scan + push to GCP Artifact Registry

### CD Pipeline (`.github/workflows/cd.yml`) — Triggered after CI succeeds on `main`:
- Checkov + TFSec Terraform security scan
- WIF auth to GCP
- Verify images in Artifact Registry
- Fetch secrets from GCP Secret Manager
- Update GitOps manifests + push to Git
- GitOps sync agent auto-deploys on VM

### Required Secrets

| Secret Name | Used In | Required |
|---|---|---|
| `GCP_PROJECT_ID` | CI + CD | Yes |
| `GCP_REGION` | CI + CD | Yes |
| `GCP_SA_EMAIL` | CI + CD | Yes |
| `GCP_WIF_PROVIDER` | CI + CD | Yes |
| `SNYK_TOKEN` | CI | Yes |
| `SONAR_TOKEN` | CI | Yes |
| `SONAR_HOST_URL` | CI | Yes |

`GITHUB_TOKEN` is automatically provided — no setup needed.

---

## 2. GCP Workload Identity Federation

WIF provides keyless authentication from GitHub Actions to GCP (no JSON key files needed).

Terraform creates the WIF pool, provider, and service account automatically. After `terraform apply`, get the values:

```bash
terraform output service_account_email  # -> GCP_SA_EMAIL
terraform output wif_provider           # -> GCP_WIF_PROVIDER
```

| Secret | Value |
|---|---|
| `GCP_PROJECT_ID` | `expadox-lab` |
| `GCP_REGION` | `us-central1` |
| `GCP_SA_EMAIL` | `cloudopshub-app-dev@expadox-lab.iam.gserviceaccount.com` |
| `GCP_WIF_PROVIDER` | `projects/129303118923/locations/global/workloadIdentityPools/cloudopshub-github-dev/providers/github-provider` |

---

## 3. Snyk

Snyk scans Node.js dependencies for known vulnerabilities.

1. Go to https://app.snyk.io/login — sign up with GitHub
2. Go to https://app.snyk.io/account — copy your API Token

| Secret | Value |
|---|---|
| `SNYK_TOKEN` | Your API token |

---

## 4. SonarCloud

SonarCloud performs static code analysis for bugs and security issues.

1. Go to https://sonarcloud.io — log in with GitHub
2. Create a project for CloudOpsHub with key `cloudopshub-theepicbook`
3. Go to https://sonarcloud.io/account/security — generate a token

| Secret | Value |
|---|---|
| `SONAR_TOKEN` | Your generated token |
| `SONAR_HOST_URL` | `https://sonarcloud.io` |

---

## 5. Adding Secrets to GitHub

1. Go to https://github.com/lakunzy7/CloudOpsHub/settings/secrets/actions
2. Click **New repository secret** for each secret listed above

---

## 6. Testing the Pipeline

### Test CI
```bash
git commit --allow-empty -m "test: trigger CI pipeline"
git push origin main
```
Watch at https://github.com/lakunzy7/CloudOpsHub/actions

### Test CD
CD triggers automatically after CI succeeds on `main`. Check that:
- Terraform security scans run
- Images are verified in Artifact Registry
- GitOps manifests are updated and pushed
- GitOps sync agent deploys on VM within 60s

### Verify images
```bash
gcloud artifacts docker images list \
  us-central1-docker.pkg.dev/expadox-lab/cloudopshub-docker --include-tags
```

---

## 7. Troubleshooting

### WIF auth fails with "invalid_target"
- WIF pool/provider may not exist — run `terraform apply`
- Verify `GCP_WIF_PROVIDER` secret matches `terraform output wif_provider`

### Snyk fails with "Authentication failed"
- Verify `SNYK_TOKEN` at https://app.snyk.io/account

### SonarCloud fails with "project not found"
- Create the project on sonarcloud.io with key `cloudopshub-theepicbook` and org `lakunzy7`

### CD images not found
- CI must complete first — images are pushed during CI
- Verify with: `gcloud artifacts docker images list us-central1-docker.pkg.dev/expadox-lab/cloudopshub-docker`

---

## Quick Reference

| Service | URL |
|---|---|
| GitHub Actions | https://github.com/lakunzy7/CloudOpsHub/actions |
| GitHub Secrets | https://github.com/lakunzy7/CloudOpsHub/settings/secrets/actions |
| GCP Console | https://console.cloud.google.com/?project=expadox-lab |
| Artifact Registry | https://console.cloud.google.com/artifacts?project=expadox-lab |
| Snyk | https://app.snyk.io |
| SonarCloud | https://sonarcloud.io |
