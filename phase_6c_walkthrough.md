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
*   **InitContainer:** Fixes `vm.max_map_count` for ElasticSearch.
*   **Service:** Port 9000.

```bash
kubectl apply -f ops/k8s/sonarqube/sonarqube.yaml
```

### 1.2 Expose via Ingress
Create the Ingress rule to make it accessible at `https://sonarqube.devcloudproject.com`.

```bash
kubectl apply -f ops/k8s/sonarqube/ingress.yaml
```

### 1.3 Setup SonarQube Project
1.  Go to `https://sonarqube.devcloudproject.com`.
2.  Login with `admin` / `admin` (Change password when prompted).
3.  Create a **New Project** -> "Manually".
4.  **Project Key:** `amazon-clone-backend`.
5.  **Project Display Name:** `Amazon Clone Backend`.
6.  **Generate Token:** Name it `jenkins-token` (or `gitlab-token`) and **SAVE IT**.

---

## 🦊 Step 2: Deploy GitLab Runner
We need a "worker" in our cluster to execute GitLab pipelines.

### 2.1 Get Registration Token
1.  Go to your Project in **GitLab.com**.
2.  **Settings** -> **CI/CD** -> **Runners** -> **New Project Runner**.
3.  Copy the **Registration Token**.

### 2.2 Configure and Deploy
Update `ops/k8s/gitlab/runner.yaml` with your token and deploy it.

```bash
kubectl apply -f ops/k8s/gitlab/runner.yaml
```

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
