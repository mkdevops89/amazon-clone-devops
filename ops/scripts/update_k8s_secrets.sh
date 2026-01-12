#!/bin/bash
set -e

# Configuration
TF_DIR="$(dirname "$0")/../terraform/aws"
SECRETS_FILE="$(dirname "$0")/../k8s/db-secrets.yaml"

echo "🔍 Fetching Terraform Outputs..."
cd "$TF_DIR"
TF_JSON=$(terraform output -json)

# Extract Values using Python (to avoid dependency on jq)
read -r RDS_ENDPOINT REDIS_ENDPOINT MQ_ENDPOINT MQ_PASSWORD ECR_BACKEND ECR_FRONTEND <<< $(python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    rds = data.get('rds_endpoint', {}).get('value', 'UNKNOWN')
    redis = data.get('redis_endpoint', {}).get('value', 'UNKNOWN')
    mq = data.get('mq_endpoint', {}).get('value', 'UNKNOWN')
    mq_pass = data.get('mq_password', {}).get('value', 'UNKNOWN')
    ecr_back = data.get('ecr_backend_url', {}).get('value', 'UNKNOWN')
    ecr_front = data.get('ecr_frontend_url', {}).get('value', 'UNKNOWN')
    print(f'{rds} {redis} {mq} {mq_pass} {ecr_back} {ecr_front}')
except Exception as e:
    print('ERROR ERROR ERROR ERROR ERROR ERROR')
" <<< "$TF_JSON")

if [[ "$RDS_ENDPOINT" == "ERROR" ]]; then
    echo "❌ Error parsing Terraform output. Did you run 'terraform apply'?"
    exit 1
fi

echo "✅ RDS Endpoint: $RDS_ENDPOINT"
echo "✅ Redis Endpoint: $REDIS_ENDPOINT"
echo "✅ MQ Endpoint:    $MQ_ENDPOINT"

# Fetch RDS Password from AWS Secrets Manager
# We search for the secret created by the RDS module (prefix 'amazon-db' or similar)
echo "🔍 Fetching RDS Password from AWS Secrets Manager..."
SECRET_ARN=$(aws secretsmanager list-secrets --filters Key=name,Values=rds!db --query "SecretList[0].ARN" --output text)

if [[ "$SECRET_ARN" == "None" ]]; then
    echo "⚠️  Could not find RDS Secret automatically. Please input manually."
    read -sp "Enter RDS Password: " DB_PASSWORD
    echo ""
else
    DB_PASSWORD=$(aws secretsmanager get-secret-value --secret-id "$SECRET_ARN" --query SecretString --output text | python3 -c "import sys, json; print(json.load(sys.stdin)['password'])")
    echo "✅ Retrieved RDS Password from $SECRET_ARN"
fi

# Clean up Endpoints (remove port if needed, or format JDBC)
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

echo "🎉 Secrets Updated Successfully!"
echo "➡️  Next Step: kubectl apply -f ops/k8s/db-secrets.yaml"
