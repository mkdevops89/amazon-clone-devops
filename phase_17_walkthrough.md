# Phase 17: Ultimate Cloud-Native Cybersecurity Architecture

This walkthrough documents **every single command and file** used to build and verify the four pillars of our DevSecOps architecture: the immutable AWS S3 Evidence Room, the Kyverno Cryptographic Supply Chain Block, and the Sysdig Falco eBPF Kernel Alerts.

---

## Part 1: Architecture Setup & Automation

### 1. AWS Native Security & Immutable S3 (Terraform)
We provisioned togglable AWS Security Hub, Amazon GuardDuty, CloudTrail, and a strict WORM (Write Once, Read Many) S3 bucket.

**Files Created:**
*   `ops/terraform/aws/security.tf`: Provisions the "Ephemeral SOC".
*   `ops/terraform/aws/s3_evidence.tf`: Provisions the `amazon-clone-security-evidence` WORM bucket.

**Execution Commands:**
```bash
cd ops/terraform/environments/dev
terraform init
# Note: var.enable_ephemeral_soc defaults to false to save money.
terraform apply -auto-approve
```

### 2. Supply Chain Cryptography (Cosign)
We generated a mathematical public/private keypair to sign our proprietary Docker images.

**Files Created:**
*   `ops/k8s/kyverno/cosign.key` (Private Key - securely vaulted in K8s)
*   `ops/k8s/kyverno/cosign.pub` (Public Key)

**Execution Commands:**
```bash
# Generate the keypair
mkdir -p ops/k8s/kyverno 
export COSIGN_PASSWORD=portfolio-secure
docker run --rm -v $(pwd)/ops/k8s/kyverno:/keys -w /keys -e COSIGN_PASSWORD=portfolio-secure bitnami/cosign:latest generate-key-pair

# Vault the Private Key into the DevSecOps Kubernetes Namespace for Jenkins to use
kubectl create secret generic cosign-keys -n devsecops --from-file=cosign.key=ops/k8s/kyverno/cosign.key --from-file=cosign.pub=ops/k8s/kyverno/cosign.pub
```

### 3. Supply Chain Enforcement (Kyverno Helm)
We installed Kyverno and applied a strict policy that violently blocks any `amazon-clone` container lacking our signature.

**Files Created:**
*   `ops/k8s/kyverno/policy.yaml`: The strict Zero-Trust `ClusterPolicy` binding the `cosign.pub` key.

**Execution Commands:**
```bash
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update
helm install kyverno kyverno/kyverno -n kyverno --create-namespace
kubectl apply -f ops/k8s/kyverno/policy.yaml
```

### 4. Runtime Threat Detection (Sysdig Falco eBPF)
We deployed Falco as a DaemonSet to intercept dangerous Linux syscalls via modern eBPF.

**Files Created:**
*   `ops/helm/falco/values.yaml`: Customized rules for detecting bash shells and `/etc/shadow` reads.

**Execution Commands:**
```bash
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm repo update
helm install falco falcosecurity/falco -n falco --create-namespace -f ops/helm/falco/values.yaml
```

---

## Part 2: Security Verification & Validation (The "Simulated Hacks")

### A. The Supply Chain Block (Kyverno Zero-Trust)

We have configured Kyverno to aggressively reject any container matching our proprietary ECR registry (`406312601212.dkr.ecr.us-east-1.amazonaws.com/amazon-*`) if it was not explicitly run through our Jenkins pipeline and signed with our private `cosign` key. 

To prove this works, we will simulate a "Supply Chain Attack" by attempting to manually launch an unsigned image.

**Test Command:**
```bash
# Attempt to run a container from our registry that HAS NOT been cryptographically signed
kubectl run hacker-pod --image=406312601212.dkr.ecr.us-east-1.amazonaws.com/amazon-backend:unsigned-hack --restart=Never
```

**Expected Result:**
Kyverno will intercept the Kubernetes API request, fail to find the `.sig` mathematical artifact attached to the image, and violently reject the pod deployment with a `403 Forbidden` error!

*(Note: Because of our Portfolio-Optimized strategy, running public images like `kubectl run hello --image=nginx` will still work perfectly without disruption).*

---

---

### B. The Runtime Alert (Sysdig Falco eBPF)

Sysdig Falco acts as our invisible "Kernel Security Camera." We configured it to throw Critical alerts if anyone attempts to spawn a bash shell inside a running pod or read the `/etc/shadow` password hashes. 

To prove this works, we will simulate an attacker who has bypassed the front door (perhaps via an RCE vulnerability) and gained remote execution on our backend.

**Test Command 1 (The Break-In):**
We will intentionally spawn a shell inside a legitimate, running backend pod.
```bash
export BACKEND_POD=$(kubectl get pods -n devsecops -l app=amazon-app-backend -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $BACKEND_POD -n devsecops -- /bin/sh
```
*(Once you get a `#` prompt, type `cat /etc/shadow` to read the password hashes, then type `exit`)*

**Test Command 2 (The Incident Response):**
We check the Falco native logs to see if it immediately caught our syscall intrusion!
```bash
kubectl logs -l app.kubernetes.io/name=falco -n falco | grep -A 2 -B 2 "Terminal shell in container"
```

**Expected Result:**
You will see a massive JSON/text alert identifying the exact container `amazon-app-backend`, the fact that a `spawned_process` occurred, and the `mitre_execution` tag! This alert is natively forwarded via Filebeat to our Kibana SIEM Dashboard!

---

### C. The Executive Audit (S3 WORM Storage)

The Jenkins CI/CD pipeline (`Jenkinsfile`) was heavily modified to execute `syft` (SBOM generation) and `cosign` (Image Signing). It natively archives all JSON reports directly to S3. To prove WORM works:

**Test Command (The Tamper Attempt):**
```bash
# Dynamically find our unique evidence bucket
export EVIDENCE_BUCKET=$(aws s3api list-buckets --query "Buckets[?starts_with(Name, 'amazon-clone-security-evidence')].Name" --output text)

# Attempt to maliciously delete our vulnerability scans!
aws s3 rm s3://$EVIDENCE_BUCKET/cloudtrail/ --recursive
```

**Expected Result:**
The AWS API will violently reject the command with an `AccessDenied` or `ObjectLocked` error, proving that even a compromised IAM Administrator account physically cannot delete the compliance logs for 7 years!

