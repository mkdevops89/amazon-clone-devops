#!/bin/bash
# Install RabbitMQ on Amazon Linux 2023

# 1. Update and Install Erlang
# AL2023 provides a compatible erlang version in default repos
dnf update -y
dnf install -y erlang

# 2. Install RabbitMQ Server
# We use the RHEL/CentOS 9 (EL9) package as AL2023 is closer to EL9 userspace
rpm --import https://github.com/rabbitmq/signing-keys/releases/download/2.0/rabbitmq-release-signing-key.asc

# Install RabbitMQ 3.12.x (Standard EL8/9 RPM)
dnf install -y https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.12.12/rabbitmq-server-3.12.12-1.el8.noarch.rpm

# 3. Start & Enable
systemctl start rabbitmq-server
systemctl enable rabbitmq-server

# 4. Enable Management Plugin (Port 15672) & Fix Cookie
rabbitmq-plugins enable rabbitmq_management

# 5. Create User
# Wait for service to be fully ready
sleep 5
rabbitmqctl add_user admin password123
rabbitmqctl set_user_tags admin administrator
rabbitmqctl set_permissions -p / admin ".*" ".*" ".*"

echo "RabbitMQ Installed and Configured"
