#!/bin/bash
set -e

# Configuration
TF_DIR="$(dirname "$0")/../terraform/aws"
SECRETS_FILE="$(dirname "$0")/../k8s/db-secrets.yaml"

echo "🔍 Fetching Terraform Outputs..."
cd "$TF_DIR"

# Helper function to get output safely
get_tf_output() {
    terraform output -raw "$1" 2>/dev/null || echo "ERROR"
}

# Helper for sensitive output
get_tf_sensitive() {
    terraform output -json "$1" 2>/dev/null | tr -d '"' || echo "ERROR"
}

RDS_ENDPOINT=$(get_tf_output rds_endpoint)
REDIS_ENDPOINT=$(get_tf_output redis_endpoint)
MQ_ENDPOINT=$(get_tf_output mq_endpoint)
# MQ Password is sensitive, use -json and strip quotes
MQ_PASSWORD=$(get_tf_sensitive mq_password)
ECR_BACKEND=$(get_tf_output ecr_backend_url)
ECR_FRONTEND=$(get_tf_output ecr_frontend_url)

# Verify one key value to ensure Terraform ran
if [[ "$RDS_ENDPOINT" == "ERROR" || -z "$RDS_ENDPOINT" ]]; then
    echo "❌ Error retrieving Terraform outputs. Did you run 'terraform apply'?"
    exit 1
fi

echo "✅ RDS Endpoint: $RDS_ENDPOINT"
echo "✅ Redis Endpoint: $REDIS_ENDPOINT"
echo "✅ MQ Endpoint:    $MQ_ENDPOINT"

# Fetch RDS Password from AWS Secrets Manager
echo "🔍 Fetching RDS Password from AWS Secrets Manager..."
SECRET_ARN=$(aws secretsmanager list-secrets --filters Key=name,Values=rds!db --query "SecretList[0].ARN" --output text)

if [[ "$SECRET_ARN" == "None" ]]; then
    echo "⚠️  Could not find RDS Secret automatically. Please input manually."
    read -sp "Enter RDS Password: " DB_PASSWORD
    echo ""
else
    # Fetch Secret Value (JSON) and extract "password" field using regex/cut (No jq/python needed)
    SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id "$SECRET_ARN" --query SecretString --output text)
    # Extract value inside "password": "VALUE"
    DB_PASSWORD=$(echo "$SECRET_JSON" | grep -o '"password": *"[^"]*"' | cut -d'"' -f4)
    
    if [[ -z "$DB_PASSWORD" ]]; then
        echo "❌ Failed to parse password from Secret JSON. Manual input required."
        read -sp "Enter RDS Password: " DB_PASSWORD
        echo ""
    else
        echo "✅ Retrieved RDS Password from $SECRET_ARN"
    fi
fi

# Clean up Endpoints
# RDS Endpoint comes as host:port
DB_HOST=$(echo $RDS_ENDPOINT | cut -d: -f1)

# MQ Endpoint comes as "amqps://host:port", we need "host"
MQ_HOST=$(echo $MQ_ENDPOINT | sed 's/amqps:\/\///' | cut -d: -f1)

echo "📝 Updating $SECRETS_FILE..."

# Use sed to replace values in db-secrets.yaml
# We use a temp file to avoid race conditions/partial writes
TEMP_FILE="${SECRETS_FILE}.tmp"
cp "$SECRETS_FILE" "$TEMP_FILE"

# Replace DB URL
sed -i '' "s|db_url:.*|db_url: \"jdbc:mysql://${RDS_ENDPOINT}/amazon_db?useSSL=false\&allowPublicKeyRetrieval=true\&createDatabaseIfNotExist=true\"|" "$TEMP_FILE"

# Replace DB Password
# Escape special chars in password for sed
ESCAPED_DB_PASS=$(printf '%s\n' "$DB_PASSWORD" | sed -e 's/[\/&]/\\&/g')
sed -i '' "s|db_password:.*|db_password: \"${ESCAPED_DB_PASS}\"|" "$TEMP_FILE"

# Replace Redis Host
sed -i '' "s|redis_host:.*|redis_host: \"${REDIS_ENDPOINT}\"|" "$TEMP_FILE"

# Replace RabbitMQ Host
sed -i '' "s|rabbitmq_host:.*|rabbitmq_host: \"${MQ_HOST}\"|" "$TEMP_FILE"

# Replace RabbitMQ Password
ESCAPED_MQ_PASS=$(printf '%s\n' "$MQ_PASSWORD" | sed -e 's/[\/&]/\\&/g')
sed -i '' "s|rabbitmq_password:.*|rabbitmq_password: \"${ESCAPED_MQ_PASS}\"|" "$TEMP_FILE"

mv "$TEMP_FILE" "$SECRETS_FILE"

# ==========================================
# 2. Inject ECR URLs into Manifests
# ==========================================
BACKEND_FILE="$(dirname "$0")/../k8s/backend.yaml"
FRONTEND_FILE="$(dirname "$0")/../k8s/frontend.yaml"

echo "📝 Updating ECR URLs in Manifests..."

# Escaping slashes in ECR URLs for sed
ESCAPED_ECR_BACKEND=$(printf '%s\n' "$ECR_BACKEND" | sed -e 's/[\/&]/\\&/g')
ESCAPED_ECR_FRONTEND=$(printf '%s\n' "$ECR_FRONTEND" | sed -e 's/[\/&]/\\&/g')

# Update Backend Manifest
sed -i '' "s|image: <ECR_BACKEND_URL>:latest|image: ${ESCAPED_ECR_BACKEND}:latest|" "$BACKEND_FILE"

# Update Frontend Manifest
sed -i '' "s|image: <ECR_FRONTEND_URL>:latest|image: ${ESCAPED_ECR_FRONTEND}:latest|" "$FRONTEND_FILE"

echo "🎉 Secrets & Images Updated Successfully!"
echo "➡️  Next Step: kubectl apply -f ops/k8s/db-secrets.yaml"
