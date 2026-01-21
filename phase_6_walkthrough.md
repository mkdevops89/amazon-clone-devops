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

### 🔐 Step 1: Configure Secrets
Add these secrets to your GitHub Repository so the pipeline can access them safely.

1.  Go to **GitHub Repo** -> **Settings** -> **Secrets and variables** -> **Actions**.
2.  Click **New repository secret**.
3.  Add the following:
    *   `SNYK_TOKEN`: (Your Snyk API Key)
    *   `SONAR_TOKEN`: (Your SonarCloud Token)
    *   `AWS_ACCESS_KEY_ID`: (Your AWS Access Key)
    *   `AWS_SECRET_ACCESS_KEY`: (Your AWS Secret Key)

---

### 🚀 Step 2: Push & Trigger CI
The **DevSecOps CI** pipeline triggers automatically on every push.

1.  **Push the code:**
    ```bash
    git add .
    git commit -m "feat: Add DevSecOps pipelines"
    git push origin phase-6a-githubactions
    ```
2.  **Monitor the Run:**
    *   Go to **Actions** tab in GitHub.
    *   Click on the **DevSecOps CI** workflow.
    *   Watch the steps:
        *   **TruffleHog:** Scans for leaked secrets in git history.
        *   **Snyk:** Checks `pom.xml` and `package.json` for vulnerable libraries.
        *   **SonarCloud:** Analyzes code quality and bugs.
        *   **Trivy:** Scans the file system for container vulnerabilities.

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
