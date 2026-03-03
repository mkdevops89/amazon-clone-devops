#!/bin/bash
# Install Redis on Amazon Linux 2023
dnf update -y
# AL2023 typically provides 'redis6' or 'redis'. We will try both.
dnf install -y redis6 || dnf install -y redis

# Determine config file location
if [ -f /etc/redis6/redis6.conf ]; then
    CONFIG_FILE="/etc/redis6/redis6.conf"
    SERVICE_NAME="redis6"
elif [ -f /etc/redis/redis.conf ]; then
    CONFIG_FILE="/etc/redis/redis.conf"
    SERVICE_NAME="redis"
elif [ -f /etc/redis.conf ]; then
    CONFIG_FILE="/etc/redis.conf"
    SERVICE_NAME="redis"
else
    echo "Redis config file not found!"
    exit 1
fi


# Configure Redis to listen on all interfaces (Private IP)
# By default it listens on localhost only.
sed -i 's/^bind 127.0.0.1/bind 0.0.0.0/' $CONFIG_FILE
sed -i 's/^protected-mode yes/protected-mode no/' $CONFIG_FILE

# Start & Enable
systemctl enable $SERVICE_NAME
systemctl start $SERVICE_NAME

echo "Redis ($SERVICE_NAME) Installed and Configured"
