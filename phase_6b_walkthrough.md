# Phase 6b: Enterprise Self-Hosted (Jenkins & Nexus) 🏯

In this phase, we simulate an "Enterprise" environment where we own the entire CI/CD stack.
Instead of using Cloud SaaS (GitHub Actions), we deploy our own **Jenkins** server and **Nexus** repository manager on our Kubernetes cluster.

---

## 🏗️ Step 1: Infrastructure Setup

### 1. Install EBS CSI Driver (CRITICAL) 💾
Since you want to use the **"Right Resources"** (Persistent Volumes), we need to install the storage driver on your cluster.
Without this, your pods will stay `Pending` because they can't create disks!

**The Easy Way (Scripted):**
I've created a script to handle the IAM Role and Add-on installation automatically.

Run this:
```bash
chmod +x ops/scripts/install_ebs_driver.sh
./ops/scripts/install_ebs_driver.sh
```
*(This will check your account ID, create the IAM Role if missing, and install the driver.)*

### 2. Infrastructure Setup (Namespace & Storage) 💾
First, create the namespace and the storage class.
**IMPORTANT:** Do not skip this!

```bash
kubectl apply -f ops/k8s/namespace.yaml
kubectl apply -f ops/k8s/storage-class.yaml
```

### 3. Update Certificate ARN & Deploy Apps
Now deploy the apps (which will use the new `gp3` storage).

> [!IMPORTANT]
> **Resource Optimization Applied:**
> Due to the cluster running on a single small node (t3.medium or similar), I've reduced the Jenkins and Nexus memory requests to **512Mi** each. 
> I also scaled down system components like `coredns` and `aws-load-balancer-controller` to 1 replica to free up "pod slots" on the node.

Run this command to replace the placeholders:
```bash
# Set the ACM ARN found in your AWS Console
export ACM_CERTIFICATE_ARN="arn:aws:acm:us-east-1:406312601212:certificate/9e3aa5f9-1cec-488b-943c-6994089e3775"

envsubst < ops/k8s/nexus/nexus.yaml | kubectl apply -f -
envsubst < ops/k8s/jenkins/jenkins.yaml | kubectl apply -f -
```

> [!TIP]
> **Troubleshooting: Permission Denied on Volumes?**
> I've added `initContainers` to both `jenkins.yaml` and `nexus.yaml` that automatically run `chown` on the mount points. This fixes the common "Permission Denied" error when mounting EBS volumes as a non-root user.

---

## 🔒 Step 2: Configure Route53 DNS (Shared ALB) ☁️
Since we configured Jenkins and Nexus to join the existing "amazon-group" load balancer, **you do NOT need a new Load Balancer**.
They will share the same ALB as your main app, saving you money! 💰

**How to get the Load Balancer DNS Name:**
Run this command in your terminal:
```bash
kubectl get ingress -n default amazon-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```
*(Result: `k8s-amazongroup-629b6c7264-839863946.us-east-1.elb.amazonaws.com`)*

1.  Go to **Route53** -> **Hosted Zones**.
2.  Create two new records:
    *   **Name:** `jenkins.devcloudproject.com` -> **Value:** (Paste ALB DNS Name). Select "Alias" -> Yes.
    *   **Name:** `nexus.devcloudproject.com` -> **Value:** (Paste ALB DNS Name). Select "Alias" -> Yes.

---

## 🔓 Step 3: Unlock Jenkins & Nexus

### Unlock Jenkins
1.  **URL:** Go to `https://jenkins.devcloudproject.com`
2.  **Initial Password:** `497e1b2074af4579a7ed29d00af0ff05` (Retrieved via `kubectl exec`)
3.  **Setup Wizard:**
    *   Paste the password.
    *   Select **"Install Suggested Plugins"**.
    *   Create your Admin User (e.g., `admin` / `password`).
    *   Save and Finish.

### Unlock Nexus
1.  **URL:** Go to `https://nexus.devcloudproject.com`
2.  Click **Sign In** (top right).
3.  **Username:** `admin`
4.  **Initial Password:** `2e840eff-a549-488c-9f82-bfdcce38b389` (Retrieved via `kubectl exec`)
5.  Follow the wizard (Change password, allow anonymous access for now).

---

## 🛠️ Infrastructure Fixes Applied (Post-Mortem)
During deployment, we encountered and fixed several real-world production issues:
1.  **Storage Engine:** Installed AWS EBS CSI Driver and configured `gp3` StorageClass for dynamic provisioning.
2.  **Volume Permissions:** Added `initContainers` to handle `chown` for Jenkins (UID 1000) and Nexus (UID 200).
3.  **Resource Constraints:** Downsized system components and application requests to fit on a single-node cluster.
4.  **Ingress Group Conflicts:** Patched existing Ingresses (`amazon-ingress`, `grafana-ingress`) that had invalid placeholders, which was blocking the entire ALB Group from reconciling.

---

## ⚙️ Step 4: Configure Jenkins

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

## 📝 Step 5: Create the Pipeline

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

## 🚀 Step 6: Run the Build manually
1.  Click **Build Now**.
2.  Click the flashing **#1** in Build History.
3.  Click **Console Output** to watch the magic!

---

## 📦 Step 7: Configure Nexus Repositories
Now that Nexus is running, you need to create the places where your code artifacts and Docker images will "live".

### 1. Create a Maven Repository (for .jar files)
1.  Log in to Nexus as `admin`.
2.  Click the **Settings (Gear icon)** at the top.
3.  Go to **Repository** -> **Repositories**.
4.  Click **Create repository** -> select **maven2 (hosted)**.
5.  **Name:** `amazon-maven-releases`.
6.  **Deployment Policy:** Allow redeploy (for development) or Disable redeploy (for strict releases).
7.  Click **Create repository**.

### 2. Create a Docker Repository (for Images)
1.  Click **Create repository** -> select **docker (hosted)**.
2.  **Name:** `amazon-docker-repo`.
3.  **HTTP Connector:** Check "HTTP" and enter port `8082` (Note: You may need to update the Kubernetes Service/Ingress later if you want to push directly via this port).
4.  **Enable Docker V1 API:** Optional.
5.  Click **Create repository**.

### 3. Setup Credentials in Jenkins
To allow Jenkins to push to Nexus:
1.  Go to Jenkins -> **Manage Jenkins** -> **Credentials**.
2.  (global) -> **Add Credentials**.
3.  **Kind:** Username with password.
4.  **Username:** `admin` (or create a specific `deployment` user in Nexus).
5.  **Password:** Your Nexus admin password.
6.  **ID:** `nexus-credentials`.
7.  Click **Create**.

> [!TIP]
> **Next Level:** In a real production setup, you would create a "Group" repository in Nexus that combines your hosted code and a "Proxy" to Maven Central, so developers only need one URL for everything.
