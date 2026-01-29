# Phase 6c: GitLab CI & SonarQube Integration

## 🎯 Goal
Migrate our CI/CD pipeline to a **GitLab Hybrid Model** and implement **SonarQube** for continuous code quality inspection.
*   **GitLab CI:** Use GitLab.com for the UI but run builds on our own Kubernetes cluster (Private Runner).
*   **SonarQube:** Host a private SonarQube server to scan code for bugs and security vulnerabilities.

---

## 🛠️ Step 1: Deploy SonarQube
We need a place to send our code quality reports.

### 1.1 Create the Deployment
Apply the SonarQube manifest which includes:
*   **Persistence:** 10GB PVC to save data.
*   **InitContainers:** Fixes `vm.max_map_count` and volume permissions (chown 1000:1000).
*   **Service:** Port 9000.

```bash
kubectl apply -f ops/k8s/sonarqube/sonarqube.yaml
```

### 1.2 Expose via Ingress (DNS & SSL)
Create the Ingress rule to make it accessible at `https://sonarqube.devcloudproject.com`.

**Important:** We use the same `${ACM_CERTIFICATE_ARN}` variable as before.

```bash
export ACM_CERTIFICATE_ARN=$(cd ops/terraform/aws && terraform output -raw acm_certificate_arn)
envsubst < ops/k8s/sonarqube/ingress.yaml | kubectl apply -f -
```

### 1.3 Configure Route53 (Manual Step)
Since we are using partial automation, you need to point the domain to the Load Balancer manually.
1.  **Get ALB Hostname:** `kubectl get ingress -n devsecops sonarqube-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'`
2.  **Go to Route53** -> **Hosted Zones**.
3.  **Create Record:**
    *   **Name:** `sonarqube.devcloudproject.com`
    *   **Type:** `A` (Alias)
    *   **Value:** (Select your `amazon-group` ALB)
    *   **Routing Policy:** Simple

### 1.4 Setup SonarQube Project
1.  Go to `https://sonarqube.devcloudproject.com`.
2.  Login with `admin` / `admin` (Change password when prompted).

> [!NOTE]
> You will see a warning: *"Embedded database should be used for evaluation purposes only"*.
> **This is normal.** For this lab, we use the internal H2 database to save money. In a real production environment, we would connect this to an AWS RDS PostgreSQL instance.

3.  Create a **New Project** -> "Manually".
4.  **Project Key:** `amazon-clone-backend`.
5.  **Project Display Name:** `Amazon Clone Backend`.
6.  **Main Branch Name:** `main` (if prompted).
7.  **Generate Token:** Name it `gitlab-ci-token` and **SAVE IT** (You will need it for GitLab Variables).

---

## 🦊 Step 2: Deploy GitLab Runner (The Hybrid Model)
**Why do this?**
Instead of using shared runners (which are slow and cost money/minutes), we deploy our own "Worker" inside our EKS cluster.
This gives us:
*   **Security:** Code never leaves our VPC during build.
*   **Speed:** Direct access to internal services (like SonarQube).
*   **Cost:** No per-minute billing.

### 2.1 Register on GitLab
1.  Create a Free Account on [GitLab.com](https://gitlab.com).
2.  **New Project** -> **Create blank project**.
    *   **Project name:** `amazon-clone-devops`.
    *   **Visibility:** Private or Public.
3.  **Get the Runner Token:**
    *   Go to **Settings** -> **CI/CD**.
    *   Expand **Runners**.
    *   Click **New Project Runner**.
    *   **Tags:** Add `amazon-clone` (Crucial! The pipeline will look for this tag).
    *   Click **Create runner**.
    *   **COPY and SAVE** the `runner-registration-token` (starts with `glrt-`).

### 2.2 Configure and Deploy
Update the runner manifest with your specific token.

```bash
# Export your token
export GITLAB_TOKEN="glrt-YOUR_TOKEN_HERE"

# Deploy (using sed to inject token temporarily)
sed "s/REPLACE_ME_WITH_TOKEN/$GITLAB_TOKEN/g" ops/k8s/gitlab/runner.yaml | kubectl apply -f -
```
*(Note: In production, we would use Secrets, but this is fine for learning).*

### 2.3 Connect Local Repo to GitLab
Now that the project is created, we need to upload our code.

```bash
# 1. Add GitLab as a new remote (so we don't break GitHub)
git remote add gitlab https://gitlab.com/YOUR_USERNAME/amazon-clone-devops.git

# 2. Push your current branch to GitLab
git push -u gitlab phase-6c-gitlab
```
*(Replace `YOUR_USERNAME` with your actual GitLab username)*.

> [!IMPORTANT]
> **Authentication Error?**
> If you get `HTTP Basic: Access denied`, it's because you cannot use your GitLab account password. You must use a **Personal Access Token**.
> 1. Go to GitLab **User Settings** -> **Access Tokens**.
> 2. Create a new token with **write_repository** scope.
> 3. Use your **Username** and this **Token** (as the password) when pushing.
>
> Or update the remote url to include it:
> `git remote set-url gitlab https://oauth2:YOUR_TOKEN@gitlab.com/YOUR_USERNAME/amazon-clone-devops.git`

---

### 2.4 Configure Secret Variables
We need to give GitLab the SonarQube token securely.

1.  Go to your GitLab Project -> **Settings** -> **CI/CD**.
2.  Expand **Variables**.
3.  Click **Add variable**.
    *   **Key:** `SONAR_TOKEN`
    *   **Value:** (Paste your SonarQube token from Step 1.4)
    *   **Type:** Variable
    *   **Flags:** Check "Mask variable" (to hide it in logs).
4.  Click **Add variable**.

---

## 🚀 Step 3: The Pipeline (.gitlab-ci.yml)
We define our pipeline stages in the root of the repository.

1.  **Infrastructure Scan:** (New) Checkov scans our Terraform for cloud misconfigurations.
2.  **Build:** Compile Java code.
3.  **Code Quality:** Run `mvn sonar:sonar`.
4.  **Container Scan:** (New) Trivy scans the filesystem and dependencies for CVEs.
5.  **Deploy:** Update the Kubernetes cluster.

---

## ✅ Verification
*   **SonarQube:** Check the dashboard for the "Green" Quality Gate.
*   **GitLab:** Ensure the pipeline passes.
