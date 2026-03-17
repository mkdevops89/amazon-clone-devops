# Decommissioning & Disaster Recovery Master Runbook

## 1. Executive Summary
This document provides the **exact, flawless terminal commands** required to completely tear down the AWS Amazon-Clone infrastructure to stop billing (~$100/mo), and the precise steps to rebuild the entire DevSecOps architecture from scratch.

Because this architecture blends Terraform with GitOps (ArgoCD), recovery requires a specific sequence to restore both the hardware (AWS) and the software (Kubernetes workloads).

---

## 2. 🔴 The Decommissioning Phase (Tear Down)
To completely stop AWS compute billing, you must destroy the infrastructure.

### Step 1: Preserve Persistent Data (EBS Volumes)
By default, Kubernetes deletes EBS hard drives when the cluster is destroyed. You must forcefully decouple the volumes from the cluster lifecycle by patching them to `Retain`.
```bash
kubectl get pv -o name | xargs -I {} kubectl patch {} -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'
```
*Verify the patch worked by running `kubectl get pv`. The `RECLAIM POLICY` column must say `Retain` before proceeding.*

### Step 2: Execute Terraform Destroy
Run this command to vaporize the EKS Cluster, VPC, NAT Gateways, ALBs, and Compute Instances:
```bash
cd ops/terraform/environments/dev
terraform destroy -auto-approve
```

### Step 2: The S3 WORM Blockade (Expected Error)
> [!WARNING]
> **Terraform Destroy *WILL* Fail on the S3 Evidence Bucket**

In Phase 17, we enabled **S3 Object Lock (WORM)** in `COMPLIANCE` mode. AWS physically prevents the deletion of this bucket or its contents for 7 years to satisfy SOC2/PCI audits. 
*   **Result:** Terraform will successfully destroy the expensive compute resources, but will throw an `AccessDenied` error when attempting to destroy the S3 bucket.
*   **Action:** This is normal and expected. The bucket costs mere pennies per month. You have successfully stopped the $100/month compute billing.

---

## 3. 🟢 The Disaster Recovery Phase (Rebuild)
When you are ready to demonstrate the portfolio to a hiring manager, follow this exact sequence to resurrect the architecture.

### Step 1: Rebuild the AWS Hardware (Terraform)
This provisions the bare-metal VPC, networking, and the empty EKS cluster.
```bash
cd ops/terraform/environments/dev
terraform apply -auto-approve
```
Wait ~20 minutes for completion.

### Step 2: Authenticate with the New EKS Cluster
Terraform builds the cluster, but you must tell your local laptop how to talk to it.
```bash
aws eks update-kubeconfig --region us-east-1 --name amazon-clone-eks
```

### Step 3: Install Critical AWS Drivers
The cluster is empty. It needs drivers to attach EBS hard drives (for SonarQube/Jenkins) and to build ALBs (for Ingress). Run the scripts we built in earlier phases:
```bash
cd ops/scripts
chmod +x install_ebs_driver.sh install_lb_controller.sh
./install_ebs_driver.sh
./install_lb_controller.sh
```

### Step 4: Re-bind Orphaned EBS Volumes (Data Recovery)
> [!IMPORTANT]
> Because you preserved the EBS volumes in the Decommissioning phase, AWS has detached them, and they are sitting in your account as "Available". 
> Before proceeding to Step 5, you must reattach the old Jenkins/SonarQube/Nexus data to the new cluster:
> 1. Log into the AWS Console -> EC2 -> Volumes.
> 2. Find your old "Available" volumes (they will have names like `pvc-1234...`).
> 3. You must manually create new `PersistentVolume` and `PersistentVolumeClaim` YAML manifests in the new cluster that explicitly reference the old AWS `Volume ID` (e.g., `vol-0abcd1234`).
> 4. *Only after binding the old volumes* should you proceed to install ArgoCD.

### Step 5: Install the NGINX Ingress Controller
This routes public internet traffic to the pods.
```bash
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace
```

### Step 5: Install ArgoCD (The Brains)
ArgoCD is our GitOps operator. Once installed, it will automatically rebuild everything else.
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### Step 6: Trigger the GitOps Resurgence
Point ArgoCD to your GitHub repository. ArgoCD will read the `.yaml` files in the repository and automatically pull Jenkins, SonarQube, Nexus, Grafana, Redpanda, and the Amazon Application out of thin air!
```bash
# Apply the root application that tells ArgoCD to watch the gitops repo
kubectl apply -f ops/k8s/argocd/amazon-root-app.yaml

# Create the devsecops namespace so ArgoCD can populate it
kubectl create namespace devsecops
```

### Step 7: Verify Recovery
Watch your terminal as the entire Enterprise architecture reconstructs itself:
```bash
kubectl get pods -n devsecops -w
```
Once the Jenkins pod is `Running`, log into the Jenkins UI, click "Build Now" on the `phase-17` branch, and the DevSecOps supply chain pipeline will generate the Cosign signatures and fully restore the frontend and backend applications into production!
