import boto3
import logging

logging.basicConfig(level=logging.INFO)
rds = boto3.client('rds')

print("🔎 Scanning ALL RDS Instances and their Tags...")

try:
    dbs = rds.describe_db_instances()
    if not dbs['DBInstances']:
        print("No RDS instances found.")

    for db in dbs['DBInstances']:
        db_id = db['DBInstanceIdentifier']
        status = db['DBInstanceStatus']
        arn = db['DBInstanceArn']
        
        print(f"  Found DB: {db_id} | Status: {status}")
        
        # RDS requires a separate call to get tags
        try:
            tags_response = rds.list_tags_for_resource(ResourceName=arn)
            tags = tags_response['TagList']
            tag_str = ", ".join([f"{t['Key']}={t['Value']}" for t in tags])
            print(f"     Tags: [{tag_str}]")
            
            # Check logic
            env_tag = next((t['Value'] for t in tags if t['Key'] == 'Environment'), None)
            if env_tag == 'Dev':
                print(f"     ✅ MATCH! This DB WOULD be stopped.")
            else:
                print(f"     ❌ SKIP. Tag 'Environment=Dev' missing.")
                
        except Exception as tag_err:
             print(f"     ⚠️ Check Tags Failed: {tag_err}")

except Exception as e:
    print(f"Error: {e}")
