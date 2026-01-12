#!/bin/bash
# Install MySQL 8
yum update -y
yum install -y mysql-server

# Start & Enable
systemctl start mysqld
systemctl enable mysqld

# Create Database and User (Hardcoded for Learning)
# Using `mysql -e` to execute commands
mysql -e "CREATE DATABASE IF NOT EXISTS amazon_db;"
mysql -e "CREATE USER IF NOT EXISTS 'admin'@'%' IDENTIFIED BY 'password123';"
mysql -e "GRANT ALL PRIVILEGES ON amazon_db.* TO 'admin'@'%';"
mysql -e "FLUSH PRIVILEGES;"

# Note: In production you would run `mysql_secure_installation`
echo "MySQL Installed and Configured"
