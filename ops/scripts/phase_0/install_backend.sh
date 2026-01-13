#!/bin/bash
# Install Java 17 & Maven
yum update -y
yum install -y java-17-amazon-corretto-devel maven git

# Clone Repository
cd /home/ec2-user
git clone https://github.com/mkdevops89/amazon-clone-devops.git
cd amazon-clone-devops/backend

# Configure Environment Variables (User MUST Replace These)
export SPRING_DATASOURCE_URL="jdbc:mysql://<REPLACE_WITH_DB_PRIVATE_IP>:3306/amazon_db?createDatabaseIfNotExist=true"
export SPRING_DATASOURCE_USERNAME="admin"
export SPRING_DATASOURCE_PASSWORD="password123"
export SPRING_REDIS_HOST="<REPLACE_WITH_REDIS_PRIVATE_IP>"
export SPRING_RABBITMQ_HOST="<REPLACE_WITH_MQ_PRIVATE_IP>"
export SPRING_RABBITMQ_PORT="5672"
export SPRING_RABBITMQ_USERNAME="admin"
export SPRING_RABBITMQ_PASSWORD="password123"

# Build & Run (In background)
mvn clean install -DskipTests
nohup mvn spring-boot:run > backend.log 2>&1 &

echo "Backend Started"
