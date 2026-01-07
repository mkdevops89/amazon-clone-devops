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


echo "[Step 7] Configuring Environment Variables (.env)..."
# Fetch Public IP from AWS Metadata (IMDSv2 compliant)
echo "   Attempting to fetch Public IP (IMDSv2)..."
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" --fail --silent --connect-timeout 2)

if [ -n "$TOKEN" ]; then
    PUBLIC_IP=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/public-ipv4)
else
    echo "   IMDSv2 token failed. Trying fallback methods..."
    PUBLIC_IP=$(curl -s --connect-timeout 2 http://169.254.169.254/latest/meta-data/public-ipv4 || curl -s --connect-timeout 2 ifconfig.me)
fi

if [ -z "$PUBLIC_IP" ]; then
    echo "⚠️  Could not detect Public IP. Using localhost."
    PUBLIC_IP="localhost"
else
    echo "✅ Detected Public IP: $PUBLIC_IP"
fi

# Get DD API Key from Argument or Prompt
DD_API_KEY="$1"
if [ -z "$DD_API_KEY" ]; then
    echo "⚠️  No Datadog API Key provided (optional). Usage: ./setup_ec2.sh <YOUR_KEY>"
    DD_API_KEY="placeholder_key_replace_me"
fi

# Write to .env
# Note: AWS IPs change on restart, so this overwrites .env each time script runs
cat <<EOF > .env
NEXT_PUBLIC_API_URL=http://$PUBLIC_IP:8080/api
DD_API_KEY=$DD_API_KEY
EOF

echo "✅ Generated .env file:"
echo "   NEXT_PUBLIC_API_URL=http://$PUBLIC_IP:8080/api"
echo "   DD_API_KEY=********"
echo "==================================================="
echo "✅ Docker Setup Complete!"
echo "Docker Version: $(docker --version)"
echo "Compose Version: $(docker compose version)"
echo "⚠️  IMPORTANT: Please LOG OUT and LOG BACK IN for group changes to take effect."
echo "==================================================="
