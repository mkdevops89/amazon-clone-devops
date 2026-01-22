# Phase 6: Multi-Platform CI/CD & DevSecOps 🛡️

This phase establishes a "Platinum Pipeline" using **GitHub Actions**, **Jenkins**, and **GitLab CI**.
We detect vulnerabilities *before* deployment, ensuring a secure software supply chain.

---

## 🟦 Phase 6a: Cloud-Native (GitHub Actions)

This implementation uses **GitHub Actions** for a zero-maintenance, cloud-native DevSecOps pipeline.

### 🛠️ Prerequisites
You need a GitHub repository and accounts for the security tools.

1.  **Snyk Token:**
    *   Sign up at [snyk.io](https://snyk.io).
    *   Go to **Account Settings** -> **API Token**.
    *   Copy the key.

2.  **SonarCloud Token:**
    *   Sign up at [sonarcloud.io](https://sonarcloud.io) (Login with GitHub).
    *   Create a simple project (Manual).
    *   Go to **My Account** -> **Security** -> **Generate Token**.

3.  **AWS Credentials:**
    *   Ensure you have an IAM User with `AdministratorAccess` (or sufficient EKS/ECR permissions).
    *   You need the `access_key_id` and `secret_access_key`.

---

### 📝 Step 1: Create DevSecOps Pipeline
First, we will create the **Continuous Integration (CI)** pipeline that scans for security issues.

1.  **Create file:** `.github/workflows/devsecops-ci.yaml`

---

### 📝 Step 2: Create Deployment Pipeline
Next, create the **Continuous Delivery (CD)** pipeline that deploys the app to EKS.

1.  **Create file:** `.github/workflows/deploy-app.yaml`

---

### 🔐 Step 3: Configure Secrets
Add these secrets to your GitHub Repo so the pipelines work.

1.  Go to **GitHub Repo** -> **Settings** -> **Secrets and variables** -> **Actions**.
2.  Click **New repository secret**.
3.  Add:
    *   `SONAR_TOKEN`: (SonarCloud Token)
    *   `AWS_ACCESS_KEY_ID`: (AWS Access Key)
    *   `AWS_SECRET_ACCESS_KEY`: (AWS Secret Key)
    *   *(Snyk Token optional since we disabled it)*

---

### 🚀 Step 4: Run the Pipelines
Since we set them to **Manual Only**, you must trigger them yourself.

1.  **Run Security Checks:**
    *   Go to **Actions** tab -> **DevSecOps CI**.
    *   Click **Run workflow**.

2.  **Run Deployment:**
    *   Go to **Actions** tab -> **Deploy App to EKS**.
    *   Click **Run workflow**.

---

## 🚨 Troubleshooting: Restoring Deleted Workflows
If you accidentally delete the workflow files, you can recreate them by copying the code below.

### 1. DevSecOps CI
**File:** `.github/workflows/devsecops-ci.yaml`
```yaml
name: DevSecOps CI

on:
  workflow_dispatch: # Manual trigger only

jobs:
  security-checks:
    name: DevSecOps Pipeline
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v3
        with:
          fetch-depth: 0 # Required for TruffleHog git history scan

      # 1. Secret Scanning (TruffleHog)
      - name: Secret Scanning (TruffleHog)
        uses: trufflesecurity/trufflehog@main
        with:
          path: ./
          base: ${{ github.event.repository.default_branch }}
          head: HEAD
          extra_args: --debug --only-verified

      # 2. SCA - Dependency Scanning (Snyk)
      # Checks Maven (Backend) and Node keys (Frontend)
      # - name: Snyk Monitor (Backend)
      #   uses: snyk/actions/maven@master
      #   continue-on-error: true # Warning only for demo
      #   env:
      #     SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
      #   with:
      #     args: --file=backend/pom.xml

      # - name: Snyk Monitor (Frontend)
      #   uses: snyk/actions/node@master
      #   continue-on-error: true
      #   env:
      #     SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
      #   with:
      #     args: --file=frontend/package.json

      # 3. SAST - Static Analysis (SonarCloud)
      # Requires SONAR_TOKEN and a project set up in SonarCloud
      - name: SonarCloud Scan
        uses: SonarSource/sonarcloud-github-action@master
        continue-on-error: true
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}

      # 4. Container Scanning (Trivy)
      # Scans the repo for Docker-related vulnerabilities
      - name: Run Trivy Vulnerability Scanner (Repo Mode)
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          scan-ref: '.'
          trivy-config: trivy.yaml
          format: 'table'
          exit-code: '0' # Don't fail for now
          ignore-unfixed: true
```

### 2. Deploy App
**File:** `.github/workflows/deploy-app.yaml`
```yaml
name: Deploy App to EKS

on:
  workflow_dispatch: # Manual trigger for safety
  release:
    types: [published]

permissions:
  id-token: write # Required for requesting the JWT
  contents: read  # Required for actions/checkout

jobs:
  deploy:
    name: Deploy to EKS
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v3

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v1
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Update Kubeconfig
        run: aws eks update-kubeconfig --name amazon-cluster --region us-east-1

      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v1

      - name: Deploy using Script
        # Assumes runner has docker, kubectl, envsubst
        env:
          AWS_ACCOUNT_ID: ${{ steps.login-ecr.outputs.registry }} # Use registry ID from login step
          DOMAIN_NAME: devcloudproject.com
        run: |
            chmod +x ops/scripts/deploy_k8s.sh
            ./ops/scripts/deploy_k8s.sh

  dast-scan:
    name: DAST (OWASP ZAP)
    needs: deploy
    runs-on: ubuntu-latest
    steps:
      - name: ZAP Baseline Scan
        uses: zaproxy/action-baseline@v0.14.0
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          docker_name: 'ghcr.io/zaproxy/zaproxy:stable'
          target: 'https://www.devcloudproject.com'
          cmd_options: '-a' # Include alpha rules
```

---

## 🟧 Phase 6b: Enterprise (Jenkins & Nexus)
*(Coming Soon - Requires Cluster Infrastructure Setup)*

## 🦊 Phase 6c: Integrated (GitLab CI)
*(Coming Soon)*
