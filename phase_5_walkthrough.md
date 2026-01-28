# Phase 5: Domains & HTTPS 🔐

This phase secures your application using **AWS Certificate Manager (ACM)** and **Route53**.
It relies on the **AWS Load Balancer Controller** to bridge Kubernetes Ingress with AWS ALBs.

---

## 🛠️ Prerequisites
1.  **Cluster & Backend/Frontend deployed** (or ready to deploy).
2.  **Helm Installed**.

### 1. Install Load Balancer Controller
Ensure the controller is installed (it allows `Ingress` to create ALBs).
```bash
chmod +x ops/scripts/install_lb_controller.sh
./ops/scripts/install_lb_controller.sh

# Verify Installation (Wait 1-2 mins):
kubectl get deployment -n kube-system aws-load-balancer-controller
# Expected: 2/2 or 1/1 READY
```

---

## 🏗️ Step 1: Provision SSL Certificate
Use Terraform to request a free SSL Certificate from AWS ACM.

1.  **Apply Terraform:**
    ```bash
    cd ops/terraform/aws
    terraform init
    terraform apply
    # Type 'yes' to confirm
    ```
    *   *Result:* This requests a certificate for `*.devcloudproject.com`.

---

## 🔐 Step 2: Inject Certificate ARN
We need to tell Kubernetes which Certificate to use. We have a script that fetches the ARN from Terraform and updates your manifests.

1.  **Run Update Script:**
    ```bash
    cd ../../../  # Return to project root
    chmod +x ops/scripts/update_ingress_cert.sh
    ./ops/scripts/update_ingress_cert.sh
    ```
    *   *Result:* `ops/k8s/ingress.yaml` now contains your specific ACM ARN.

---

## 🚀 Step 3: Deploy & Build (Automated)
We have a unified script `deploy_k8s.sh` that handles:
1.  **Building the Frontend** (baking in `https://api.devcloudproject.com`).
2.  **Pushing to ECR**.
3.  **Deploying to EKS** (Frontend, Backend, Ingress, Monitoring).

1.  **Run Deployment:**
    ```bash
    chmod +x ops/scripts/deploy_k8s.sh
    ./ops/scripts/deploy_k8s.sh
    ```
    *   *Time:* ~3-5 minutes (Docker build + Push).

---

## 🌐 Step 4: Update DNS (Route53)
Connect your Domain to the new Load Balancer created by the Ingress.

1.  **Get Load Balancer Address:**
    ```bash
    kubectl get ingress amazon-ingress
    ```
    *   *Copy the ADDRESS* (e.g., `k8s-default-amazonin-....us-east-1.elb.amazonaws.com`).

2.  **Update Route53 Records:**
    *   Go to **AWS Console -> Route53 -> Hosted Zones** -> Click your domain (`devcloudproject.com`).
    *   Click **Create Record**:
        *   **Record Name:** (Leave Empty for root domain).
        *   **Record Type:** `A`
        *   **Alias:** Toggle **ON** (Blue Switch).
        *   **Route traffic to:**
            1.  Choose **Alias to Application and Classic Load Balancer**.
            2.  Choose Region: **US East (N. Virginia)** `us-east-1`.
            3.  Search/Select your load balancer (e.g., `k8s-amazongroup...`).
        *   Click **Create records**.
    *   **Repeat for Subdomains (`www`, `api`, `grafana`):**
        *   Follow the same steps, but enter `www`, `api`, or `grafana` in the **Record Name**.

---

## ✅ Step 5: Verify
1.  Open `https://www.devcloudproject.com`.
2.  **Log In** and verify Products List loads.
3.  Open `https://api.devcloudproject.com/actuator/health` -> `{"status":"UP"}`.

---

## 🧹 Cleanup
To saves resources:
```bash
# 1. Delete Ingress (Deletes ALB)
kubectl delete ingress amazon-ingress grafana-ingress

# 2. Uninstall Controller
helm uninstall aws-load-balancer-controller -n kube-system

# 3. Destroy Terraform
cd ops/terraform/aws
terraform destroy
```
