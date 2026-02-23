# Walkthrough: Phase 12 (Ansible Configuration & Auditing)

In this phase, we demonstrated two distinct ways to use Ansible in modern cloud architectures:
1. **Track A (The Pet)**: Traditional Configuration Management on a dedicated EC2 Bastion host.
2. **Track B (The Cattle)**: Modern Dynamic Auditing using the AWS EC2 Inventory plugin to query our GitOps/EKS endpoints.

## 0. Prerequisites & Infrastructure Setup

Before running any playbooks, you must first provision the Bastion Host via Terraform. Because you opted to pause infrastructure builds for the night, you will need to run these commands tomorrow to prepare the environment:

```bash
# 1. Navigate to the Terraform directory
cd ops/terraform/aws

# 2. Apply the new Bastion infrastructure (this creates the EC2 instance and SSH Keys)
terraform init
terraform apply -auto-approve

# 3. Secure the newly generated Ansible private key
chmod 400 ../../ansible/keys/ansible-bastion.pem
```

*Note: You must have the required Python libraries for the AWS dynamic inventory plugin to work:*
```bash
python3 -m pip install boto3 botocore
```

---

## 1. Track A: Traditional Configuration Management (Bastion)

We have created an `admin-server.yaml` playbook that will SSH into the newly created Bastion host. It upgrades packages, installs `fail2ban` security controls, configures a new `admin` user with sudo privileges, and installs standard DevOps tooling like `kubectl` and `helm`.

**To execute:**
```bash
cd ops/ansible

# Verify Ansible can interact with your AWS account and pull the Bastion dynamically
ansible-inventory -i inventory/aws_ec2.yaml --graph

# Ping the Bastion to ensure SSH/Keys are functioning
ansible -i inventory/aws_ec2.yaml tag_Name_ansible_bastion -m ping

# Run the Configuration Management Playbook
ansible-playbook -i inventory/aws_ec2.yaml playbooks/admin-server.yaml
```

### Verification & Test Cases (Track A)

Once the playbook completes, run these ad-hoc commands to prove the configurations succeeded without having to SSH into the box:

```bash
# 1. Verify fail2ban is actively running
ansible -i inventory/aws_ec2.yaml tag_Name_ansible_bastion -b -m command -a "systemctl status fail2ban"

# 2. Verify Docker daemon is running
ansible -i inventory/aws_ec2.yaml tag_Name_ansible_bastion -b -m command -a "systemctl status docker"

# 3. Verify CloudWatch Agent is running
ansible -i inventory/aws_ec2.yaml tag_Name_ansible_bastion -b -m command -a "systemctl status amazon-cloudwatch-agent"

# 4. Verify Root SSH is explicitly disabled
ansible -i inventory/aws_ec2.yaml tag_Name_ansible_bastion -b -m command -a "grep '^PermitRootLogin' /etc/ssh/sshd_config"

# 5. Verify AL2023 Firewall (firewalld - UFW equivalent) is active
ansible -i inventory/aws_ec2.yaml tag_Name_ansible_bastion -b -m command -a "systemctl status firewalld"

# 6. Verify DevOps CLI tools are installed
ansible -i inventory/aws_ec2.yaml tag_Name_ansible_bastion -m command -a "kubectl version --client"
ansible -i inventory/aws_ec2.yaml tag_Name_ansible_bastion -m command -a "aws --version"
```

*Notice how we didn't have to specify an IP address! We told Ansible to target `tag_Name_ansible_bastion`, which the `aws_ec2` plugin dynamically translated into the exact public IP of the EC2 instance Terraform built.*

---

## 2. Track B: Modern Dynamic Auditing

Since ArgoCD natively handles deploying and configuring our application containers on EKS, utilizing Ansible to "configure" Kubernetes deployments is considered a slight anti-pattern. Instead, we elevate Ansible to act as an external testing and auditing engine to ensure the dynamic applications are truly accessible to the world.

We created `health-checks.yaml`, which runs locally and fires HTTP requests against our public URLs to ensure GitOps delivered successfully.

**To execute:**
```bash
cd ops/ansible

# Run the API and Frontend Health Checks
ansible-playbook playbooks/health-checks.yaml
```

If the GitOps pipeline deployed everything correctly in Phase 11.5, Ansible will report that the Frontend returns the correct `amazon-orange` CSS, the backend API returns a valid JSON list of products, and the Jenkins Jenkins UI returns a 200 OK. 

### Auditing EKS Worker Nodes
We also created an `eks-audit.yaml` playbook. This playbook dynamically discovers *all* running EKS worker nodes by filtering on the `tag_kubernetes_io_cluster_amazon_app_eks` AWS tag, eliminating the need to update an inventory list when nodes scale up or down.

```bash
# Audit the internal EKS worker nodes
# (Note: Requires VPN/Internal network access to the nodes to succeed)
ansible-playbook -i inventory/aws_ec2.yaml playbooks/eks-audit.yaml
```

### Verification & Test Cases (Track B)

You can run individual ad-hoc commands to verify Track B without running the full playbook. This proves that Ansible can dynamically audit your live AWS infrastructure.

```bash
# 1. Verify AWS Dynamic Inventory is correctly discovering EKS nodes without IP addresses
ansible-inventory -i inventory/aws_ec2.yaml --graph

# 2. Verify SSM Agent is running on all discovered EKS nodes simultaneously
ansible -i inventory/aws_ec2.yaml tag_eks_cluster_name_amazon_cluster -b -m command -a "systemctl status amazon-ssm-agent"

# 3. Verify Amazon Inspector is running on all discovered EKS nodes
ansible -i inventory/aws_ec2.yaml tag_eks_cluster_name_amazon_cluster -b -m command -a "systemctl status amazon-inspector-agent"
```
