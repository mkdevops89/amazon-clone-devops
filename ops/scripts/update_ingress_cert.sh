#!/bin/bash
set -e

# Define paths
TF_DIR="ops/terraform/aws"
INGRESS_FILE="ops/k8s/ingress.yaml"

echo "🔍 Fetching Certificate ARN from Terraform..."
# Get the ARN using terraform output
if [ -d "$TF_DIR" ]; then
    CERT_ARN=$(cd "$TF_DIR" && terraform output -raw acm_certificate_arn 2>/dev/null)
else
    echo "❌ Terraform directory not found at $TF_DIR"
    exit 1
fi

# Check if ARN is retrieved
if [[ -z "$CERT_ARN" || "$CERT_ARN" == *"No outputs found"* ]]; then
    echo "❌ Could not retrieve Certificate ARN. Did you run 'terraform apply'?"
    exit 1
fi

echo "✅ Found ARN: $CERT_ARN"

# Replace placeholder in Ingress file
echo "🔧 Injecting ARN into $INGRESS_FILE..."

# MacOS requires empty string for -i (sed -i '')
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s|<INSERT_YOUR_ACM_ARN>|$CERT_ARN|g" "$INGRESS_FILE"
else
    sed -i "s|<INSERT_YOUR_ACM_ARN>|$CERT_ARN|g" "$INGRESS_FILE"
fi

echo "✅ Validating injection..."
grep "$CERT_ARN" "$INGRESS_FILE"

echo "🎉 Success! Ingress manifest updated."
echo "   Next: kubectl apply -f $INGRESS_FILE"
