# Phase 10: Immutable Infrastructure (Packer)

**Goal**: Stop "configuring" servers. Bake the configuration into the image itself.
**Role**: Cloud Engineer.

## 🛠 Prerequisites
*   **Packer**: Installed (`brew install packer`).
*   **AWS CLI**: Configured.

## 📝 Concept
*   **Mutable**: Docker runs -> Ansible installs Java. (Slow, risky).
*   **Immutable**: Packer starts VM -> Installs Java -> Saves as AMI -> Docker just runs Java. (Fast, reliable).

## 📝 Step-by-Step Runbook

### 1. Create Template
Navigate to `ops/packer`.
The file `backend.pkr.hcl` defines:
1.  **Source AMI**: Amazon Linux 2.
2.  **Builders**: EC2 `t2.micro`.
3.  **Provisioners**: Shell scripts to install Java.

### 2. Validate
Check for syntax errors.
```bash
cd ops/packer
packer init .
packer validate .
```

### 3. Build the Image
This spins up a temporary EC2 instance in AWS, runs the scripts, and saves the AMI.
```bash
packer build backend.pkr.hcl
```
*   **Time**: ~5 minutes.
*   **Output**: `ami-0abcdef123456`

### 4. Use the Image (Terraform)
Now you need to tell Terraform to use this new AMI instead of the generic one.
Edit `ops/terraform/aws/main.tf` (or your variables):
```hcl
variable "ami_id" {
  default = "ami-0abcdef123456" # Use Your ID
}
```

### 5. Verification
Deploy Terraform and SSH into the new instance.
```bash
java -version
# Expected: "OpenJDK 17"
# If you didn't need to run 'yum install', you succeeded!
```

## 🚀 Troubleshooting
*   **"VPCIdNotSpecified"**: Packer needs a default VPC to launch the temporary builder instance. Ensure you have a default VPC in `us-east-1` or specify `vpc_id` in the builder config.
