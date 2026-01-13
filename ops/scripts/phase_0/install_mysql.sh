#!/bin/bash
# Install MySQL (MariaDB) on Amazon Linux 2023
# AL2023 uses MariaDB 10.5 as the default MySQL-compatible database.
dnf update -y
dnf install -y mariadb105-server

# Start & Enable
# Service name is 'mariadb'
systemctl start mariadb
systemctl enable mariadb

# Create Database and User
# 'mysql' command is provided by mariadb-server
mysql -e "CREATE DATABASE IF NOT EXISTS amazon_db;"
mysql -e "CREATE USER IF NOT EXISTS 'admin'@'%' IDENTIFIED BY 'password123';"
mysql -e "GRANT ALL PRIVILEGES ON amazon_db.* TO 'admin'@'%';"
mysql -e "FLUSH PRIVILEGES;"

echo "MySQL (MariaDB) Installed and Configured"
