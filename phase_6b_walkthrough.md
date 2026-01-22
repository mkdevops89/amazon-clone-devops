# Phase 6b: Enterprise Self-Hosted (Jenkins & Nexus) 🏯

In this phase, we simulate an "Enterprise" environment where we own the entire CI/CD stack.
Instead of using Cloud SaaS (GitHub Actions), we deploy our own **Jenkins** server and **Nexus** repository manager on our Kubernetes cluster.

---

## 🏗️ Step 1: Deploy Infrastructure

We need to launch Jenkins and Nexus into a new namespace called `devsecops`.

### 1. Update Certificate ARN
First, we need to make sure the Ingresses use your correct AWS Certificate ARN.

**Troubleshooting: Missing ARN?**
If you see `Error: Output "acm_certificate_arn" not found`, it means Terraform state doesn't have it yet (or needs `terraform apply`).
You can manually find it in AWS Console -> Certificate Manager (ACM).

**Command:**
```bash
# 1. Try to get ARN from Terraform
export ACM_ARN=$(terraform -chdir=ops/terraform/aws output -raw acm_certificate_arn)

# 2. If valid, deploy:
envsubst < ops/k8s/nexus/nexus.yaml | kubectl apply -f -
envsubst < ops/k8s/jenkins/jenkins.yaml | kubectl apply -f -
```

### 2. Configure Route53 DNS (Shared ALB) ☁️
Since we configured Jenkins and Nexus to join the existing "amazon-group" load balancer, **you do NOT need a new Load Balancer**.
They will share the same ALB as your main app, saving you money! 💰

1.  Go to **AWS Console** -> **EC2** -> **Load Balancers**.
2.  Find the `k8s-amazon-group-...` Load Balancer.
3.  Copy its **DNS Name**.
4.  Go to **Route53** -> **Hosted Zones**.
5.  Create two new records:
    *   **Name:** `jenkins.devcloudproject.com` -> **Value:** (Paste ALB DNS Name). Select "Alias" -> Yes.
    *   **Name:** `nexus.devcloudproject.com` -> **Value:** (Paste ALB DNS Name). Select "Alias" -> Yes.

### 3. Verify Pods
Wait for the pods to be `Running`. This might take 2-3 minutes.
```bash
kubectl get pods -n devsecops
```

---

## 🔓 Step 2: Unlock Jenkins & Nexus

### Unlock Jenkins
1.  **URL:** Go to `https://jenkins.devcloudproject.com`
2.  **Get Initial Password:**
    ```bash
    kubectl exec -it -n devsecops deployment/jenkins -- cat /var/jenkins_home/secrets/initialAdminPassword
    ```
3.  **Setup Wizard:**
    *   Paste the password.
    *   Select **"Install Suggested Plugins"**.
    *   Create your Admin User (e.g., `admin` / `password`).
    *   Save and Finish.

### Unlock Nexus
1.  **URL:** Go to `https://nexus.devcloudproject.com`
2.  Click **Sign In** (top right).
3.  **Username:** `admin`
4.  **Get Initial Password:**
    ```bash
    kubectl exec -it -n devsecops deployment/nexus -- cat /nexus-data/admin.password
    ```
5.  Follow the wizard (Change password, allow anonymous access for now).

---

## ⚙️ Step 3: Configure Jenkins

We need to tell Jenkins how to talk to Kubernetes to spawn "Agent" pods for building our app.

1.  **Install Kubernetes Plugin:** (Should be installed, but check `Manage Jenkins` -> `Plugins`).
2.  **Configure Cloud:**
    *   Go to `Manage Jenkins` -> `Clouds`.
    *   Add a new cloud -> **Kubernetes**.
    *   **Kubernetes URL:** `https://kubernetes.default.svc`
    *   **Kubernetes Namespace:** `devsecops`
    *   **Jenkins URL:** `http://jenkins.devsecops.svc.cluster.local:8080`
    *   **Jenkins Tunnel:** `jenkins.devsecops.svc.cluster.local:50000`
    *   Test Connection.

---

## 📝 Step 4: Create the Pipeline

1.  Click **New Item** on Jenkins Dashboard.
2.  Name: `amazon-clone`.
3.  Type: **Pipeline**.
4.  Scroll to **Pipeline** section.
5.  Definition: **Pipeline script from SCM**.
6.  SCM: **Git**.
7.  Repository URL: `https://github.com/mkdevops89/amazon-clone-devops.git`
8.  Branch Specifier: `*/phase-6b-jenkins`
9.  Script Path: `Jenkinsfile`
10. Click **Save**.

---

## 🚀 Step 5: Run the Build manually
1.  Click **Build Now**.
2.  Click the flashing **#1** in Build History.
3.  Click **Console Output** to watch the magic!
