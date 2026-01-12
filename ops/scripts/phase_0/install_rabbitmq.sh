#!/bin/bash
# Install RabbitMQ on Amazon Linux 2023
yum update -y

# 1. Install Erlang (Dependency)
# Using Amazon Linux Extras if available, or direct yum
yum install -y erlang

# 2. Install RabbitMQ Server
# Need to add repository first usually, but check if available in base
# For Amazon Linux 2023, might need to curl the rpm
rpm --import https://github.com/rabbitmq/signing-keys/releases/download/2.0/rabbitmq-release-signing-key.asc
curl -O https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.12.12/rabbitmq-server-3.12.12-1.el8.noarch.rpm
yum install -y rabbitmq-server-3.12.12-1.el8.noarch.rpm

# 3. Start & Enable
systemctl start rabbitmq-server
systemctl enable rabbitmq-server

# 4. Enable Management Plugin (Port 15672)
rabbitmq-plugins enable rabbitmq_management

# 5. Create User
rabbitmqctl add_user admin password123
rabbitmqctl set_user_tags admin administrator
rabbitmqctl set_permissions -p / admin ".*" ".*" ".*"

echo "RabbitMQ Installed and Configured"
