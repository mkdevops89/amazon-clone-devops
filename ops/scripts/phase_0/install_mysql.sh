#!/bin/bash
# Install MySQL (MariaDB) on Amazon Linux 2023
# AL2023 uses MariaDB 10.5 as the default MySQL-compatible database.
dnf update -y
dnf install -y mariadb105-server

# Install Git to fetch backup
dnf install -y git

# Setup working directory
cd /home/ec2-user
# Clone the repository (Phase 0 Branch)
git clone -b phase-0-ec2 https://github.com/mkdevops89/amazon-clone-devops.git

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

# Import Data (If file exists)
BACKUP_FILE="/home/ec2-user/amazon-clone-devops/backend/src/main/resources/db_backup.sql"
if [ -f "$BACKUP_FILE" ]; then
    echo "Importing $BACKUP_FILE..."
    mysql -u root amazon_db < "$BACKUP_FILE"
    echo "Data Import Successful"
else
    echo "WARNING: Backup file not found at $BACKUP_FILE"
fi

echo "MySQL (MariaDB) Installed and Configured"
