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
2.  **Paste content:**
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
              fetch-depth: 0 # Required for TruffleHog

          # 1. Secret Scanning (TruffleHog)
          - name: Secret Scanning (TruffleHog)
            uses: tricot-io/trufflehog-github-action@master
            with:
              path: ./
              base: ${{ github.event.repository.default_branch }}
              head: HEAD
              extra_args: --debug --only-verified

          # 2. SCA - Dependency Scanning (Snyk)
          # (Commented out to save costs)
          # - name: Snyk Monitor (Backend)
          #   ...
          #   ...

          # 3. SAST - Static Analysis (SonarCloud)
          - name: SonarCloud Scan
            uses: SonarSource/sonarcloud-github-action@master
            continue-on-error: true
            env:
              GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
              SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}

          # 4. Container Scanning (Trivy)
          - name: Run Trivy Scanner
            uses: aquasecurity/trivy-action@master
            with:
              scan-type: 'fs'
              scan-ref: '.'
              format: 'table'
              ignore-unfixed: true
    ```

---

### 📝 Step 2: Create Deployment Pipeline
Next, create the **Continuous Delivery (CD)** pipeline that deploys the app to EKS.

1.  **Create file:** `.github/workflows/deploy-app.yaml`
2.  **Paste content:**
    ```yaml
    name: Deploy App to EKS

    on:
      workflow_dispatch: # Manual trigger
      release:
        types: [published]

    permissions:
      id-token: write
      contents: read

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
            env:
              AWS_ACCOUNT_ID: ${{ steps.login-ecr.outputs.registry }}
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
            uses: zaproxy/action-baseline@v0.7.0
            with:
              target: 'https://www.devcloudproject.com'
              cmd_options: '-a'
    ```

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

### 🚀 Step 3: Trigger Deployment (Continuous Delivery)
The **Deploy App** pipeline is manual (for safety) or triggered on release.

1.  Go to **Actions** tab.
2.  Select **Deploy App to EKS**.
3.  Click **Run workflow** -> **Run workflow**.
4.  **Process:**
    *   Logs into AWS ECR.
    *   Builds & Pushes Docker Images.
    *   Deploys to EKS using `deploy_k8s.sh`.
    *   **DAST:** Runs **OWASP ZAP** against the live site (`https://www.devcloudproject.com`).

---

## 🟧 Phase 6b: Enterprise (Jenkins & Nexus)
*(Coming Soon - Requires Cluster Infrastructure Setup)*

## 🦊 Phase 6c: Integrated (GitLab CI)
*(Coming Soon)*
