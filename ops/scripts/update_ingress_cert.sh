#!/bin/bash
set -e

# Define paths
TF_DIR="ops/terraform/aws"
# Fetch ARN from Terraform
echo "🔍 Fetching Certificate ARN from Terraform..."
CERT_ARN=$(cd $TF_DIR && terraform output -raw acm_certificate_arn)
echo "   Found ARN: $CERT_ARN"

# Loop through all ingress files
FILES=("ops/k8s/ingress.yaml" "ops/k8s/ingress-grafana.yaml")

for INGRESS_FILE in "${FILES[@]}"; do
    if [ -f "$INGRESS_FILE" ]; then
        echo "🔧 Injecting ARN into $INGRESS_FILE..."
        # MacOS requires empty string for -i (sed -i '')
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s|<INSERT_YOUR_ACM_ARN>|$CERT_ARN|g" "$INGRESS_FILE"
        else
            sed -i "s|<INSERT_YOUR_ACM_ARN>|$CERT_ARN|g" "$INGRESS_FILE"
        fi
        grep "$CERT_ARN" "$INGRESS_FILE" > /dev/null && echo "   ✅ Injected" || echo "   ❌ Failed to inject"
    else
        echo "⚠️  File not found: $INGRESS_FILE"
    fi
done

echo "✅ Validating injection..."
grep "$CERT_ARN" "$INGRESS_FILE"

echo "🎉 Success! Ingress manifest updated."
echo "   Next: kubectl apply -f $INGRESS_FILE"
