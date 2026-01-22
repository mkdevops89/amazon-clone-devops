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
