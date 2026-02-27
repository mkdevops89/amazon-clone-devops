import boto3
import json
import base64
import subprocess
import os

try:
    existing_secret = subprocess.check_output(
        ["kubectl", "get", "secret", "db-secrets", "-n", "devsecops", "-o", "jsonpath={.data}"],
        stderr=subprocess.DEVNULL
    ).decode().strip()
    data = json.loads(existing_secret)
except Exception as e:
    print("Failed to get existing secret from k8s:", e)
    exit(1)

secret_payload = {}
for k, v in data.items():
    secret_payload[k] = base64.b64decode(v).decode('utf-8')

sm = boto3.client('secretsmanager', region_name='us-east-1')
try:
    sm.create_secret(
        Name='devsecops/amazon-app/db-secrets',
        SecretString=json.dumps(secret_payload)
    )
    print("✅ Secret devsecops/amazon-app/db-secrets created in AWS Secrets Manager")
except sm.exceptions.ResourceExistsException:
    sm.update_secret(
        SecretId='devsecops/amazon-app/db-secrets',
        SecretString=json.dumps(secret_payload)
    )
    print("✅ Secret devsecops/amazon-app/db-secrets updated in AWS Secrets Manager")
