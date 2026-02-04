import boto3
import json
import subprocess
import time
import base64

def get_rds_info():
    print("🔍 Fetching RDS Info...")
    rds = boto3.client('rds', region_name='us-east-1')
    try:
        response = rds.describe_db_instances(DBInstanceIdentifier='amazon-db')
        endpoint = response['DBInstances'][0]['Endpoint']['Address']
        
        # Get Secret ARN
        secret_arn = response['DBInstances'][0]['MasterUserSecret']['SecretArn']
        
        # Get Password
        sm = boto3.client('secretsmanager', region_name='us-east-1')
        secret_val = sm.get_secret_value(SecretId=secret_arn)
        password = json.loads(secret_val['SecretString'])['password']
        
        return endpoint, password
    except Exception as e:
        print(f"❌ Failed to get RDS info: {e}")
        return None, None

def get_redis_endpoint():
    print("🔍 Fetching Redis Info...")
    ec = boto3.client('elasticache', region_name='us-east-1')
    try:
        # Correct ID found via CLI
        response = ec.describe_replication_groups(ReplicationGroupId='amazon-redis-rep-group')
        endpoint = response['ReplicationGroups'][0]['NodeGroups'][0]['PrimaryEndpoint']['Address']
        return endpoint
    except Exception as e:
        print(f"❌ Failed to get Redis info: {e}")
        return None

def get_mq_info():
    print("🔍 Fetching MQ Info...")
    mq = boto3.client('mq', region_name='us-east-1')
    try:
        # List brokers to find ID
        response = mq.list_brokers()
        broker = next((b for b in response['BrokerSummaries'] if b['BrokerName'] == 'amazon-mq'), None)
        if not broker:
            print("❌ MQ Broker not found")
            return None, None, None
            
        broker_id = broker['BrokerId']
        
        # Get Endpoint (AMQPS)
        b_desc = mq.describe_broker(BrokerId=broker_id)
        # AMQPS port 5671 found in endpoints usually [0] ssl://...
        endpoint_url = b_desc['BrokerInstances'][0]['Endpoints'][0] 
        # remove wss:// or ssl:// and port
        host = endpoint_url.replace('amqps://', '').replace(':5671', '')
        
        # Reset Password since we lost it
        # User provided password (moved to env var for safety)
        import os
        new_password = os.getenv("MQ_PASSWORD", "REPLACE_WITH_REAL_PASSWORD")
        # mq.update_user(...) # We cannot update via API easily if it fails, assuming user set it or retrieved it.
        # Just returning it to generate the secret.
        print(f"⚠️  Using MQ Password from environment or placeholder.")
        
        return host, 'admin', new_password
    except Exception as e:
        print(f"❌ Failed to get MQ info: {e}")
        return None, None, None

def generate_yaml(rds_ep, rds_pw, redis_ep, mq_host, mq_user, mq_pw):
    print("📝 Generating db-secrets.yaml...")
    
    # Base64 encode values
    def b64(s):
        return base64.b64encode(s.encode()).decode()

    # Connection Strings
    db_url = f"jdbc:mysql://{rds_ep}/amazon_db?useSSL=false&allowPublicKeyRetrieval=true&createDatabaseIfNotExist=true"
    redis_host = redis_ep
    
    yaml_content = f"""apiVersion: v1
kind: Secret
metadata:
  name: db-secrets
  namespace: devsecops
type: Opaque
data:
  # Database
  db_url: {b64(db_url)}
  db_username: {b64('admin')}
  db_password: {b64(rds_pw)}
  
  # Redis
  redis_host: {b64(redis_host)}
  # application.properties uses port 6379 default, no need for port env var normally unless overridden.
  # But backend.yaml sets SPRING_DATA_REDIS_PORT explicitly to "6379", so we don't need it in secret.
  # Wait, let's include everything just in case, but keys must match backend.yaml usage.
  # backend.yaml does NOT use secret for port, so we omit.
  
  # RabbitMQ
  rabbitmq_host: {b64(mq_host)}
  rabbitmq_username: {b64(mq_user)}
  rabbitmq_password: {b64(mq_pw)}

  # JWT
  jwt_secret: {b64(os.getenv("JWT_SECRET", "mySuperSecretkeyForJwtTestingPurposesOnly1234567890"))}
"""
    
    with open('ops/k8s/db-secrets.yaml', 'w') as f:
        f.write(yaml_content)
    print("✅ ops/k8s/db-secrets.yaml created.")

if __name__ == '__main__':
    rds_ep, rds_pw = get_rds_info()
    redis_ep = get_redis_endpoint()
    mq_host, mq_user, mq_pw = get_mq_info()
    
    if rds_ep and redis_ep and mq_host:
        generate_yaml(rds_ep, rds_pw, redis_ep, mq_host, mq_user, mq_pw)
        print("🚀 Applying to K8s...")
        subprocess.run(["kubectl", "apply", "-f", "ops/k8s/db-secrets.yaml"], check=True)
        print("✅ Applied!")
    else:
        print("❌ Could not gather all secrets.")
