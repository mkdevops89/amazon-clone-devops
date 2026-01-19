# Phase 5: Domains & HTTPS 🔐

This phase secures your application using **AWS Certificate Manager (ACM)** and **Route53**.
We will also expose Grafana on a secure subdomain.

---

## 🏗️ Step 1: Provision SSL Certificate (Terraform)
We updated the Terraform configuration to include the ACM module.

1.  **Initialize Terraform:**
    ```bash
    cd ops/terraform/aws
    terraform init
    ```

2.  **Apply Changes:**
    ```bash
    terraform apply
    ```
    *   Type `yes` to confirm.
    *   Terraform will create the Certificate and Validating DNS Records.
    *   **Wait** until it completes.

---

## ☸️ Step 2: Configure Kubernetes Ingress
We need to tell the AWS Load Balancer to use our new Certificate.

1.  **Inject Certificate ARN (Automated):**
    Run this script to fetch the ARN from Terraform and update `ingress.yaml`:
    ```bash
    cd ../../../  # Go back to root
    chmod +x ops/scripts/update_ingress_cert.sh
    ./ops/scripts/update_ingress_cert.sh
    ```
    *   Verify output: `✅ Found ARN: ...`

2.  **Deploy Ingress & Bridge:**
    ```bash
    kubectl apply -f ops/k8s/grafana-bridge.yaml
    kubectl apply -f ops/k8s/ingress.yaml
    ```
    *   Wait ~2 minutes for the Load Balancer to update.

---

## 🌐 Step 3: Update DNS (Route53)
Now point your domains to the Load Balancer.

1.  **Get Load Balancer Hostname:**
    ```bash
    kubectl get ingress amazon-ingress
    ```
    *   Copy the `ADDRESS` (e.g., `k8s-default-amazoning-....us-east-1.elb.amazonaws.com`).

2.  **Update Route53 (AWS Console):**
    *   Go to **Route53 Hosted Zones**.
    *   Select `devcloudproject.com`.
    *   **Create Record** -> **Simple Routing**.
    *   **Record 1:**
        *   Name: `www`
        *   Value: Paste the ALB Address.
        *   Type: CNAME.
    *   **Record 2:**
        *   Name: `api`
        *   Value: Paste the ALB Address.
        *   Type: CNAME.
    *   **Record 3:**
        *   Name: `grafana`
        *   Value: Paste the ALB Address.
        *   Type: CNAME.

---

## ✅ Step 4: Verify
1.  Open `https://www.devcloudproject.com` (Frontend).
2.  Open `https://api.devcloudproject.com/actuator/health` (Backend).
3.  Open `https://grafana.devcloudproject.com` (Monitoring).
4.  Check the **Lock Icon** 🔒 in your browser.
