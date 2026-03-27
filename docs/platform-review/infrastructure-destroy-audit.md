# Infrastructure Decommission and Resurrection Runbook

**Target Architecture:** AWS Cloud, EKS Kubernetes, ArgoCD GitOps, Terragrunt IaC
**Objective:** Provide a mathematically precise, zero-error methodology for completely tearing down the `amazon-clone` DevSecOps footprint and physically restoring it from scratch safely.

---

## The Danger of Orphaned Cloud Resources ⚠️

Unlike traditional on-prem architectures, destroying a dynamic Kubernetes-native AWS deployment is incredibly dangerous if executed out of order. 

Kubernetes dynamically creates **Elastic Block Stores (EBS)** for databases and **Application Load Balancers (ALBs)** for networking outside of Terraform's direct tracking. If you destroy the EKS cluster using Terragrunt *before* gracefully purging the ArgoCD workloads, AWS will permanently orphan those ALBs and Elastic Network Interfaces (ENIs). 

If an orphaned ENI is firmly attached to a VPC subnet, **Terraform will intrinsically fail to destroy your VPC network**, resulting in a permanent physical resource leak and a massive idle AWS billing event!

---

## Phase 1: The Total Destruction Sequence 🔴

To completely wipe AWS back to a virgin state cleanly, you must strictly follow this reverse-dependency execution graph.

### Step 1: Purge the Kubernetes Workloads
You must gracefully strip out every dynamic load balancer and volume dynamically orchestrated by EKS.
1. Authenticate to the specific Terragrunt `dev` cluster: `aws eks update-kubeconfig --region us-east-1 --name amazon-clone-dev`
2. Eradicate the primary ArgoCD application:
   ```bash
   kubectl delete application amazon-app -n argocd
   ```
3. Physically wait ~3 minutes. Ensure the `amazon-app-backend` and `amazon-ingress` are fully deleted. This mathematically guarantees the AWS Application Load Balancer (ALB) is safely destroyed by the Cloud Controller Manager.



### Step 3: Run the Omniscient Terragrunt Teardown
Once the dynamic K8s endpoints and blob buckets are flawlessly emptied, you can safely pull the physical infrastructure plug.
1. Navigate to the core routing folder:
   ```bash
   cd ops/terraform/environments/dev
   ```
2. Command Terragrunt to parse the raw `.tfstate` files and organically calculate the reverse-dependency graph. It will systematically destroy the active AWS footprint in this precise order: 
   - `serverless` (Lambdas, EventBridge)
   - `eks` (Control Plane, Node Groups, Autoscalers)
   - `cognito` (User Pools, App Clients)
   - `dns` (Route53, ACM Certs)
   - `ecr` (Container Registries)
   - `security` / `iam` (OIDC Roles, Security Groups) 
   - `vpc` (NAT Gateways, Subnets, Routing Tables)
   
3. **Execute the Destruction Map:**
Because you structurally want to physically recycle your legacy databases and preserve the active S3 bucket logic (product images, reports, and the locked evidence room), you must specifically instruct the dependency graph to isolate and ignore the entire S3 payload block organically natively:
   ```bash
   terragrunt run-all destroy --terragrunt-exclude-dir s3
   ```
*By surgically omitting the S3 directory, your `terragrunt run-all apply` structural rebuild tomorrow will logically discover the surviving buckets still inside AWS, statically mapping your new EKS nodes directly to the legacy images natively!*

---

## Phase 2: The Infrastructure Resurrection 🟢

When the AWS console is successfully returned to an empty void, follow this structural execution path to bring the overarching system flawlessly back into a `Healthy` matrix.

### Step 1: Provision the Foundational Cloud Hardware
We must rebuild the core underlying AWS services using Terragrunt.
1. Inside the `environments/dev/` module, unleash the pipeline:
   ```bash
   terragrunt run-all apply --terragrunt-non-interactive
   ```
2. Terragrunt will autonomously deploy the raw baseline (VPCs, OpenSearch/Redis, RabbitMQ MQ Brokers, RDS MySQL clusters, Cognito, and EKS).
3. **Important Note:** Because the system was wiped, AWS will generate definitively new `host URLs` (e.g., brand new RDS Endpoint DNS strings) and organic database passwords natively stored inside the `aws-secrets-manager`.

### Step 2: Execute the CI/CD Pipeline Build
At this exact moment, your ECR registries are physically empty. The Kubernetes Pods will intrinsically throw `ImagePullBackOff` errors because there is no application code logic.
1. Trigger your `phase-20-compliance` Jenkins pipeline manually.
2. The CI/CD engine will seamlessly compile the React and Spring Boot containers, satisfy the Trivy security gates, and push the final raw Docker images into the new Amazon ECR arrays.
3. **The GitOps Connection:** During the ultimate `GitOps: Update Manifests` stage, the Jenkins scripting pipeline will aggressively query the new AWS Systems Manager values to automatically extract the newly created `COGNITO_USER_POOL_ID` and structural API keys, natively injecting them straight back into the `values.yaml` in your `gitops-dev` branch via the `sed` algorithms!

### Step 3: Synchronize the ArgoCD Mesh
Now that the explicit infrastructure exists and the Docker registries are filled, apply your GitOps payloads.
1. Instruct ArgoCD to natively pull the `amazon-app` matrix. You simply apply your overarching GitOps tracker payload directly into the cluster:
   ```bash
   kubectl apply -f ops/k8s/argocd-app.yaml
   ```
2. The fresh EKS workloads will instantly pull the brand-new microservices and ArgoCD will fully sync the environment matrix organically within minutes.
3. External Secrets Operator (ESO) will autonomously fetch the raw database `db-secrets` from the AWS backend. 

### Step 4: Zero-Touch Database Seeding & Recovery
When the EKS `amazon-app-backend` container initializes its first JVM boot cycle, the Spring Boot Hibernate driver will seamlessly execute against the virgin RDS endpoint. 
1. Because we successfully configured `spring.sql.init.mode=always` inside your Java `application.properties`, the Spring framework fundamentally executes your native `data.sql` seeder matrix automatically!
2. Zero manual database seeding execution commands are required. The JVM instantaneously spins up the SQL structural Tables, injects the baseline 12-item Amazon inventory array, and seamlessly restores the React WebApp back to a perfect `200 OK` JSON state!

The complete Decommission and Recovery sequence is definitively formalized!

---

## Phase 3: The DNS Route 53 & ALB Destruction Edge Case ⚠️

Because Kubernetes dynamically orchestrates raw AWS networking through the overarching **AWS Load Balancer Controller**, you must be acutely aware of how the destruction sequence intersects the Route 53 caching arrays.

### 1. The Dynamic ALB Evaporation
When you explicitly trigger step 1 (`kubectl delete application amazon-app`), the EKS ingress controller intercepts the deletion event and organically commands the AWS API to violently terminate your Application Load Balancers, Target Groups, and their attached Security Group rules. This physical destruction securely protects your AWS billing line but instantaneously leaves your Route 53 strings (e.g., `api.devcloudproject.com`) pointing directly into a vacant void.

### 2. The Terraform State Lookup Crash
When you eventually run `terragrunt run-all destroy`, Terraform sequentially attempts to parse the `dns` module. If your baseline infrastructure codebase utilizes a declarative `data "aws_lb" "ingress"` trace mapping to fetch the dynamic ALB URL out of AWS structurally, **the sequence will crash**.

Because the Kubernetes CSI layer logically destroyed the ALB 25 minutes ago, Terraform violently halts the pipeline, throwing: `Error: no load balancers found matching criteria`. 

**The Automated Remediation:**
If Terragrunt fails dynamically during the Route53 destruction mapping sequence, you must systematically detach the dead ALB record strictly from the `.tfstate` cache so Terraform can legally bypass the check constraint:
```bash
cd ops/terraform/environments/dev/dns

# Force-remove the dead DNS lookup object from the tracking graph
terragrunt state rm 'data.aws_lb.ingress'

# Resume the teardown procedure organically
terragrunt destroy
```

---

## Phase 4: The Mandatory "Last Mile" Manual Executions ⚠️

Because your architecture embraces a highly decoupled framework bridging stateless EC2 instances, EKS volumes, and dynamic external APIs (GitHub, Docker Hub, Cognito), a full destruction sequence organically severs these physical integrations natively.

After successfully completing the `terragrunt run-all apply` resurrection path, you are required to perform this strict manual checklist to geometrically stitch the cloud baseline back to 100% parity.

### 1. Re-Binding the Retained EBS Volumes (CI/CD & Observability)
If you explicitly architected your underlying StorageClasses to gracefully "Retain" the history of your previous Elasticsearch logging matrices, Nexus artifacts, and Jenkins pipeline datasets, EKS will inherently just provision brand-new, blank dynamic volumes during deployment by default. You must aggressively force Kubernetes to re-bind to the orphaned hard drives gracefully waiting inside the AWS Console!

**The Automated Recovery Workflow:**
Because the AWS Elastic Block Store `volumeHandles` mathematically do not change when they are temporarily detached from the dying EC2 EKS nodes, your Git repository inherently utilizes a pre-compiled, static `PersistentVolume` map natively stored inside `ops/k8s/rescued-volumes.yaml`. This file strictly traces all 8 of your historical Jenkins, Nexus, and Elasticsearch hard drives back to their direct AWS identifiers.

You safely bypass all manual YAML configurations. You simply execute the pre-built declarative storage binding organically against the clean EKS cluster. **Ensure you execute this command BEFORE dynamically syncing ArgoCD!**
```bash
# Execute the automated 8-Volume PV map rescue sequence natively:
kubectl apply -f ops/k8s/rescued-volumes.yaml
```

### 2. ArgoCD Authentication & GitOps Synchronization
ArgoCD natively deploys dynamically inside EKS, but it actively requires initial instruction to bind back to your remote GitHub tracking state.
```bash
# Push the baseline tracking application map natively through the cluster payload
kubectl apply -f ops/k8s/argocd-app.yaml

# Dynamically extract the randomly generated ArgoCD UI password payload generated by EKS
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```
*(Note: Because Jenkins, SonarQube, and Nexus exist as native Pods inside your EKS `devsecops` namespace, they will automatically resurrect via ArgoCD. If you correctly re-bound your EBS volumes in Step 1, all of your Jenkins GitHub PAT credentials and Sonar databases will instantly recover!)*

### 3. Ansible Bastion Configuration
Terraform provisions the physical bare-metal EC2 Bastion servers, but they inherently boot as blank Amazon Linux canvases. You must execute your physical Ansible playbooks to install Helm, Kubectl, Fail2Ban, and the DISA STIG baselines into the raw environments.
```bash
# Target the newly generated dynamic AWS EC2 inventory
ansible-playbook -i ops/ansible/inventory/aws_ec2.yaml ops/ansible/playbooks/admin-server.yaml --private-key ~/.ssh/your-aws-key.pem -u ec2-user

# Hard-lock the EC2 Bastion STIG security baselines
ansible-playbook -i ops/ansible/inventory/aws_ec2.yaml ops/ansible/playbooks/stig-baseline.yaml --private-key ~/.ssh/your-aws-key.pem -u ec2-user
```

### 4. AWS Cognito Identity Registration
Terragrunt flawlessly recreates the overarching AWS Cognito User Pools and structural cryptographic algorithms, but actively refuses to manually preserve human profile datasets.
* **The Manual Execution:** Your React storefront will function beautifully, but 100% of your testing emails and live OAuth profiles have been fundamentally vaporized. You are forced to literally open `https://devcloudproject.com/signup` and organically register a brand-new "Test Shopper" to dynamically inject a new, valid JSON Web Token (JWT) into your active development matrix!

---

## Phase 5: The RDS `RESTORE_SNAPSHOT_ID` Disaster Recovery

During the infrastructure teardown loop, the Terraform AWS Provider will algorithmically execute a final native snapshot of the MySQL application database (e.g., `amazon-clone-dev-final-db-snapshot`), securely saving all active Shopping Carts, Live Orders, and product arrays.

**The Automated Resurrection:**
Terraform natively refuses to assume you want to restore a database from an old snapshot unless explicitly commanded. To mathematically restore your shopping data rather than spinning up a blank database, you must aggressively inject the explicit Bash variable during the application layer execution!

```bash
cd ops/terraform/environments/dev/eks

# Inject the Snapshot ID dynamically into the Terragrunt cache directly from the bash shell!
RESTORE_SNAPSHOT_ID="your-final-snapshot-name" terragrunt apply
```
This workflow legally forces AWS into taking the historical memory block and orchestrating the cluster structurally from that exact data trace, guaranteeing a 100% clean recovery of your user state.
