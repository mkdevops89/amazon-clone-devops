#!/bin/bash
# Install RabbitMQ on Amazon Linux 2023 (AL2023)
# Reference: https://www.rabbitmq.com/docs/install-rpm#amazon-linux

# 1. Update system
dnf update -y

# 2. Configure RabbitMQ YUM Repository (using EL9 packages which work for AL2023)
cat <<EOF > /etc/yum.repos.d/rabbitmq.repo
[modern-erlang]
name=modern-erlang-el9
baseurl=https://yum1.rabbitmq.com/erlang/el/9/\$basearch https://yum2.rabbitmq.com/erlang/el/9/\$basearch
repo_gpgcheck=1
enabled=1
gpgkey=https://github.com/rabbitmq/signing-keys/releases/download/3.0/cloudsmith.rabbitmq-erlang.E495BB49CC4BBE5B.key
gpgcheck=1
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
metadata_expire=300
pkg_gpgcheck=1
autorefresh=1
type=rpm-md

[rabbitmq-el9]
name=rabbitmq-el9
baseurl=https://yum2.rabbitmq.com/rabbitmq/el/9/\$basearch https://yum1.rabbitmq.com/rabbitmq/el/9/\$basearch
repo_gpgcheck=1
enabled=1
gpgkey=https://github.com/rabbitmq/signing-keys/releases/download/3.0/cloudsmith.rabbitmq-server.9F4587F226208342.key https://github.com/rabbitmq/signing-keys/releases/download/3.0/rabbitmq-release-signing-key.asc
gpgcheck=1
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
metadata_expire=300
pkg_gpgcheck=1
autorefresh=1
type=rpm-md

[rabbitmq-el9-noarch]
name=rabbitmq-el9-noarch
baseurl=https://yum2.rabbitmq.com/rabbitmq/el/9/noarch https://yum1.rabbitmq.com/rabbitmq/el/9/noarch
repo_gpgcheck=1
enabled=1
gpgkey=https://github.com/rabbitmq/signing-keys/releases/download/3.0/cloudsmith.rabbitmq-server.9F4587F226208342.key https://github.com/rabbitmq/signing-keys/releases/download/3.0/rabbitmq-release-signing-key.asc
gpgcheck=1
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
metadata_expire=300
pkg_gpgcheck=1
autorefresh=1
type=rpm-md
EOF

# 3. Clean cache and update
dnf clean all
dnf makecache

# 4. Install Erlang and RabbitMQ
# The RabbitMQ repo provides a modern Erlang version required by recent RabbitMQ
dnf install -y erlang rabbitmq-server

# 5. Start & Enable Service
systemctl enable rabbitmq-server
systemctl start rabbitmq-server

# 6. Enable Management Plugin
rabbitmq-plugins enable rabbitmq_management

# 7. Create User
# Waiting for service to be fully up
sleep 10
rabbitmqctl add_user admin password123
rabbitmqctl set_user_tags admin administrator
rabbitmqctl set_permissions -p / admin ".*" ".*" ".*"

echo "RabbitMQ Installation Complete"
