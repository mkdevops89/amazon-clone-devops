#!/bin/bash
# Install Node.js 18
yum update -y
curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs git

# Clone Repository
cd /home/ec2-user
git clone https://github.com/mkdevops89/amazon-clone-devops.git
cd amazon-clone-devops/frontend

# Configure Environment (User MUST Replace This)
# Note: Next.js needs this at BUILD time for static pages, and RUN time for server-side.
export NEXT_PUBLIC_API_URL="http://<REPLACE_WITH_BACKEND_PRIVATE_IP>:8080"

# Install & Build
npm install
npm run build

# Start (In background on port 3000)
nohup npm start > frontend.log 2>&1 &

echo "Frontend Started"
