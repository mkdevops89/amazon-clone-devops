#!/bin/bash
set -e

# ==============================================================================
# Automated Docker Setup for EC2 (Ubuntu)
# ==============================================================================
# This script installs Docker Engine and Docker Compose V2 following official docs.
# It prevents the common issue of installing the old V1 (1.29.2) version.
# ==============================================================================

echo "[Step 1] Uninstalling old versions (if any)..."
sudo apt-get remove -y docker docker-engine docker.io containerd runc || true

echo "[Step 2] Updating package index..."
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg

echo "[Step 3] Adding Docker's official GPG key..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "[Step 4] Setting up the repository..."
echo \
  "deb [arch=\"$(dpkg --print-architecture)\" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  \"$(. /etc/os-release && echo "$VERSION_CODENAME")\" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "[Step 5] Installing Docker Engine + Compose V2..."
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "[Step 6] Adding user to 'docker' group (No Sudo)..."
sudo usermod -aG docker $USER

echo "==================================================="
echo "✅ Docker Setup Complete!"
echo "Docker Version: $(docker --version)"
echo "Compose Version: $(docker compose version)"
echo "⚠️  IMPORTANT: Please LOG OUT and LOG BACK IN for group changes to take effect."
echo "==================================================="
