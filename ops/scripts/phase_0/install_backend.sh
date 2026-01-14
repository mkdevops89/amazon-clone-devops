#!/bin/bash
# Install Java 17 & Maven
yum update -y
yum install -y java-17-amazon-corretto-devel maven git

# Clone Repository
cd /home/ec2-user
git clone -b phase-0-ec2 https://github.com/mkdevops89/amazon-clone-devops.git
cd amazon-clone-devops/backend

# Configure Environment Variables (User MUST Replace These)
export SPRING_DATASOURCE_URL="jdbc:mysql://<REPLACE_WITH_DB_PRIVATE_IP>:3306/amazon_db?createDatabaseIfNotExist=true"
export SPRING_DATASOURCE_USERNAME="admin"
export SPRING_DATASOURCE_PASSWORD="password123"
export SPRING_REDIS_HOST="<REPLACE_WITH_REDIS_PRIVATE_IP>"
export SPRING_RABBITMQ_HOST=${RABBITMQ_HOST}
export SPRING_RABBITMQ_PORT=${RABBITMQ_PORT:-5672}
export SPRING_RABBITMQ_USERNAME=${RABBITMQ_USERNAME}
export SPRING_RABBITMQ_PASSWORD=${RABBITMQ_PASSWORD}
export SPRING_RABBITMQ_SSL_ENABLED=${RABBITMQ_SSL_ENABLED:-false}

# Build & Run (In background)
mvn clean install -DskipTests
nohup mvn spring-boot:run > backend.log 2>&1 &

echo "Backend Started"
