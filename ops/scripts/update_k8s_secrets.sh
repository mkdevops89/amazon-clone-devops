#!/bin/bash
set -e

# Configuration
# Resolve absolute path to script directory to handle 'cd' usage later
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="$SCRIPT_DIR/../terraform/aws"
SECRETS_FILE="$SCRIPT_DIR/../k8s/db-secrets.yaml"
BACKEND_FILE="$SCRIPT_DIR/../k8s/backend.yaml"
FRONTEND_FILE="$SCRIPT_DIR/../k8s/frontend.yaml"

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

# Function for cross-platform replacement
# Usage: replace_in_file "search_pattern" "replacement" "file_path"
replace_in_file() {
    local pattern="$1"
    local replacement="$2"
    local file="$3"
    local tmp_file="${file}.tmp"

    # Use | as delimiter, assuming pattern/replacement don't contain it (except we escape it)
    # quoting "$pattern" inside sed is tricky, so we rely on the caller providing a full s||| command or we construct it here.
    # Simpler: Just run the sed command passed as argument $1
    
    # Actually, simpler approach: Just execute sed -> temp -> mv for each call inline to be clear.
}

# ... (Previous code) ...

echo "📝 Updating $SECRETS_FILE..."

# We will apply all substitutions in one go or sequentially using a temp file logic
# that works everywhere.
TMP_SECRETS="${SECRETS_FILE}.tmp"

# Escape special chars for substitutions
ESCAPED_DB_PASS=$(printf '%s\n' "$DB_PASSWORD" | sed -e 's/[\/&|]/\\&/g')
ESCAPED_MQ_PASS=$(printf '%s\n' "$MQ_PASSWORD" | sed -e 's/[\/&|]/\\&/g')

# Read original file, process with sed, write to temp.
# We chain sed commands to avoid multiple I/O
sed -e "s|db_url:.*|db_url: \"jdbc:mysql://${RDS_ENDPOINT}/amazon_db?useSSL=false\&allowPublicKeyRetrieval=true\&createDatabaseIfNotExist=true\"|" \
    -e "s|db_password:.*|db_password: \"${ESCAPED_DB_PASS}\"|" \
    -e "s|redis_host:.*|redis_host: \"${REDIS_ENDPOINT}\"|" \
    -e "s|rabbitmq_host:.*|rabbitmq_host: \"${MQ_HOST}\"|" \
    -e "s|rabbitmq_password:.*|rabbitmq_password: \"${ESCAPED_MQ_PASS}\"|" \
    "$SECRETS_FILE" > "$TMP_SECRETS"

mv "$TMP_SECRETS" "$SECRETS_FILE"

# ==========================================
# 2. Inject ECR URLs into Manifests
# ==========================================
# (Paths defined at top of script)

echo "📝 Updating ECR URLs in Manifests..."

# Escaping slashes in ECR URLs for sed
ESCAPED_ECR_BACKEND=$(printf '%s\n' "$ECR_BACKEND" | sed -e 's/[\/&]/\\&/g')
ESCAPED_ECR_FRONTEND=$(printf '%s\n' "$ECR_FRONTEND" | sed -e 's/[\/&]/\\&/g')

# Backend
TMP_BACKEND="${BACKEND_FILE}.tmp"
sed "s|image: <ECR_BACKEND_URL>:latest|image: ${ESCAPED_ECR_BACKEND}:latest|" "$BACKEND_FILE" > "$TMP_BACKEND"
mv "$TMP_BACKEND" "$BACKEND_FILE"

# Frontend
TMP_FRONTEND="${FRONTEND_FILE}.tmp"
sed "s|image: <ECR_FRONTEND_URL>:latest|image: ${ESCAPED_ECR_FRONTEND}:latest|" "$FRONTEND_FILE" > "$TMP_FRONTEND"
mv "$TMP_FRONTEND" "$FRONTEND_FILE"

echo "🎉 Secrets & Images Updated Successfully!"
echo "➡️  Next Step: kubectl apply -f ops/k8s/db-secrets.yaml"
