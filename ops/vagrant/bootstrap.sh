#!/bin/bash

# ==============================================================================
# Vagrant Shell Provisioner (bootstrap.sh)
# ==============================================================================
# This script runs INSIDE the Ubuntu VM when you run 'vagrant up'.
# It sets up the entire environment (Docker + App) without needing Ansible.
# ==============================================================================

# 1. Update Package Index
# -----------------------
# Ensures we have the latest list of available packages.
echo "[TASK 1] Updating Package Index"
apt-get update -y

# 2. Install Dependencies
# -----------------------
# Install packages to allow apt to use a repository over HTTPS.
echo "[TASK 2] Installing Prerequisites"
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# 3. Add Docker's Official GPG Key
# --------------------------------
# Adds security key to verify Docker packages.
echo "[TASK 3] Adding Docker GPG Key"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# 4. Set up the Docker Repository
# -------------------------------
# Adds the stable Docker repository to apt sources.
echo "[TASK 4] Adding Docker Repository"
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# 5. Install Docker Engine
# ------------------------
# Installs the Docker runtime and CLI tools.
echo "[TASK 5] Installing Docker Engine"
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io

# 6. Install Docker Compose
# -------------------------
# Downloads the standalone binary for Docker Compose.
echo "[TASK 6] Installing Docker Compose"
curl -L "https://github.com/docker/compose/releases/download/v2.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# 7. Start the Application
# ------------------------
# Navigates to the shared folder (/opt/amazonlikeapp) and starts the stack.
echo "[TASK 7] Starting the Application Stack"
cd /opt/amazonlikeapp || exit

# Run docker-compose in detached mode (-d)
docker-compose up -d

echo "==================================================="
echo "PROVISIONING COMPLETE!"
echo "You can access the app at http://192.168.33.10:3000"
echo "==================================================="
