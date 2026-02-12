# Walkthrough: Phase 11 (Advanced CI & GitOps)

In this phase, we moved from "Basic Automation" to a "Senior/Staff" architecture by focusing on container security, performance, and GitOps.

## 1. Docker Deep Dive (Security & Speed)
We refactored the Dockerfiles to implement production best practices.

### Backend Optimization
- **Layered JARs**: We extracted the Spring Boot JAR into layers (`dependencies`, `application`, etc.). Docker now caches the 400MB+ of dependencies, so only the few MBs of your code are re-uploaded during builds.
- **Hardening**: The container no longer runs as `root`. It runs as a low-privilege `spring` user.

### Frontend Optimization
- **Non-root Execution**: Refactored to run as the `nextjs` user.
- **Standalone Build**: Optimized for Next.js output tracing.

**Manual Verification:**
```bash
# Build and check the user of the new image
cd backend
docker build -t test-backend .
docker run --rm test-backend whoami # Should return 'spring'
```

---

## 2. Helmification (The Portable Plan)
We replaced static Kubernetes YAMLs with a **Helm Chart** in `ops/helm/amazon-app/`.
- This allows us to use one set of code for any environment (Dev, Staging, Prod) by just changing `values.yaml`.
- Images are now tagged with **Git Short SHAs** instead of `latest`.

---

## 3. Jenkins Deep Dive (Traceability)
The `Jenkinsfile` was completely refactored.
- **Deterministic Tagging**: Every build now tags images with the Git commit SHA (e.g., `amazon-backend:a1b2c3d`). 
- **The GitOps Spark**: Jenkins now automatically updates `ops/helm/amazon-app/values.yaml` with the new version.

### 🛠️ Manual Step: Setting up the Pipeline
1. **Create New Item**: In Jenkins, click "New Item" -> Name: `amazon-pipeline` -> Select "Pipeline".
2. **Configure SCM**: 
   - Scroll to "Pipeline" section.
   - Definition: "Pipeline script from SCM".
   - SCM: "Git".
   - Repository URL: `https://github.com/mkdevops89/amazon-clone-devops.git`.
   - Branch Specifier: `*/phase-11-gitops`.
3. **Add Credentials**: You **MUST** add these in Jenkins (Manage Jenkins -> Credentials -> Global):
   - `aws-credentials`: (Username/Password) for AWS Access Key/Secret.
   - `nvd-api-key`: (Secret Text) for OWASP Dependency-Check.
   - `sonarqube-token`: (Secret Text) for SAST results.
   - `slack-webhook`: (Secret Text) for notifications.

---

---

## 4. ArgoCD Installation & DNS Setup (GitOps Loop)
We installed **ArgoCD** into your EKS cluster to handle automated deployments. 

### 🌐 Exposing ArgoCD via Route53
To give ArgoCD a premium URL (like `argocd.devcloudproject.com`) and keep it consistent with Jenkins/Nexus:

1. **Retrieve the ACM ARN**: 
   ```bash
   cd ops/terraform/aws
   terraform output acm_certificate_arn
   ```
   *(Copy this ARN for the next step)*

2. **Patch the Service (Attach Certificate)**:
   Run this command to tell AWS to use your "Green Lock" certificate:
   ```bash
   kubectl patch svc argocd-server -n argocd -p '{"metadata":{"annotations":{"service.beta.kubernetes.io/aws-load-balancer-ssl-cert":"YOUR_ACM_ARN_FROM_STEP_1", "service.beta.kubernetes.io/aws-load-balancer-ssl-ports":"443", "service.beta.kubernetes.io/aws-load-balancer-backend-protocol":"https"}}}'
   ```

3. **Get the LoadBalancer DNS**:
   ```bash
   kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
   ```
4. **Create Route53 Record**:
   - Go to **Route53** -> **Hosted Zones** -> `devcloudproject.com`.
   - Click **Create record**.
   - Record name: `argocd`.
   - Record type: **A - Routes traffic to an IPv4 address and some AWS resources**.
   - Toggle **Alias** to **ON**.
   - **Route traffic to**: "Alias to Application and Classic Load Balancer".
   - **Region**: (e.g., `us-east-1`).
   - **Load Balancer**: Select the ArgoCD LoadBalancer from the list (it should match the hostname from Step 3).
5. **Save Record**.

### 🔐 Accessing ArgoCD
Once the DNS propagates, use the new URL:
1. **URL**: `https://argocd.devcloudproject.com`

> [!TIP]
> **"The Green Lock"**: Because you attached the ACM certificate, you should no longer see any "Insecure" warnings. The browser will now trust the connection!

2. **Username**: `admin`
3. **Get Password**:
   ```bash
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
   ```

### 🚀 Connecting the App
I've provided a manifest in `ops/k8s/argocd-app.yaml`. Once you push your changes to GitHub, run:
```bash
kubectl apply -f ops/k8s/argocd-app.yaml
```
ArgoCD will then take over the deployment!

### 🔒 Production Hardening (Persistence & Monitoring)
We have upgraded ArgoCD from "Basic" to "Production-Grade" with these enhancements:

1. **State Persistence**: 
   - A **PersistentVolumeClaim (PVC)** was added to the `argocd-redis` component.
   - This ensures that even when you use the "Stop" Lambda, ArgoCD remembers its Git cache and login state.
2. **Metrics & Observability**:
   - **ServiceMonitors** were deployed into the `monitoring` namespace.
   - Prometheus is now scraping real-time data from the ArgoCD Server, Controller, and Repo-Server. You can track "Sync Time" and "Sync Status" in your Grafana dashboards.


