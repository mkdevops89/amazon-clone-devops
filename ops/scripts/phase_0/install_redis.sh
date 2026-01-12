#!/bin/bash
# Install Redis
yum update -y
yum install -y redis

# Configure Redis to listen on all interfaces (Private IP)
# By default it listens on localhost only.
sed -i 's/^bind 127.0.0.1/bind 0.0.0.0/' /etc/redis/redis.conf
sed -i 's/^protected-mode yes/protected-mode no/' /etc/redis/redis.conf

# Start & Enable
systemctl start redis
systemctl enable redis

echo "Redis Installed and Configured"
