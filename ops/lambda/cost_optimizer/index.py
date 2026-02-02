import boto3
import logging
import os
import json
from datetime import datetime

# Setup Logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Clients
ec2 = boto3.client('ec2')
asg = boto3.client('autoscaling')
eks = boto3.client('eks')
rds = boto3.client('rds')
sns = boto3.client('sns')

SNS_TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN')

def lambda_handler(event, context):
    """
    The Cost Terminator:
    Triggered by EventBridge Rule (e.g., "Nightly Stop" or "Morning Start").
    Event Payload: {"action": "stop"} or {"action": "start"}
    """
    action = event.get('action', 'stop')
    logger.info(f"Received action: {action}")
    
    report = []

    if action == 'stop':
        report.append(scale_down_eks_nodes())
        report.append(stop_dev_instances())
        report.append(stop_dev_rds())
        report.append(cleanup_orphaned_resources())
    elif action == 'start':
        report.append(restore_eks_nodes())
        report.append(start_dev_instances())
        report.append(start_dev_rds())
    
    # Filter empty reports and join
    summary = "\n".join([r for r in report if r])
    if summary:
        publish_alert(f"Cost Terminator Report: {action.upper()}", summary)
    
    return {"status": "success", "action": action, "report": summary}

def publish_alert(subject, message):
    if SNS_TOPIC_ARN:
        sns.publish(TopicArn=SNS_TOPIC_ARN, Subject=subject, Message=message)

    
    return {"status": "success", "action": action}

def scale_down_eks_nodes():
    """Sets EKS Node Group min/desired size to 0."""
    logger.info("Scaling down EKS Node Groups...")
    # TODO: Fetch cluster name dynamically or from env
    cluster_name = os.environ.get('CLUSTER_NAME', 'amazon-cluster')
    
    try:
        nodegroups = eks.list_nodegroups(clusterName=cluster_name)['nodegroups']
        for ng in nodegroups:
            # Tag the current size so we can restore it later
            desc = eks.describe_nodegroup(clusterName=cluster_name, nodegroupName=ng)['nodegroup']
            current_min = desc['scalingConfig']['minSize']
            current_desired = desc['scalingConfig']['desiredSize']
            
            # Use EC2 Tags on the ASG or Parameter Store to save state (Simplified here)
            logger.info(f"Saving state for {ng}: min={current_min}, desired={current_desired}")
            
            # Scale to 0
            eks.update_nodegroup_config(
                clusterName=cluster_name,
                nodegroupName=ng,
                scalingConfig={'minSize': 0, 'desiredSize': 0}
            )
            logger.info(f"Scaled {ng} to 0")
    except Exception as e:
        logger.error(f"Failed to scale EKS: {e}")

def restore_eks_nodes():
    """Restores EKS Node Groups to default size (e.g., 1)."""
    logger.info("Restoring EKS Node Groups...")
    cluster_name = os.environ.get('CLUSTER_NAME', 'amazon-cluster')
    
    try:
        nodegroups = eks.list_nodegroups(clusterName=cluster_name)['nodegroups']
        for ng in nodegroups:
            # In a real scenario, read from DynamoDB/Tags. Here we default to 1.
            eks.update_nodegroup_config(
                clusterName=cluster_name,
                nodegroupName=ng,
                scalingConfig={'minSize': 1, 'desiredSize': 1}
            )
            logger.info(f"Restored {ng} to size 1")
        return f"Restored EKS Node Groups in {cluster_name} to size 1."
    except Exception as e:
        logger.error(f"Failed to restore EKS: {e}")
        return f"Error restoring EKS: {e}"

def stop_dev_instances():
    """Stops EC2 Intances tagged Environment=Dev"""
    logger.info("Stopping Dev EC2 Instances...")
    filters = [{'Name': 'tag:Environment', 'Values': ['Dev']}, {'Name': 'instance-state-name', 'Values': ['running']}]
    instances = ec2.describe_instances(Filters=filters)
    ids = [i['InstanceId'] for r in instances['Reservations'] for i in r['Instances']]
    
    if ids:
        ec2.stop_instances(InstanceIds=ids)
        logger.info(f"Stopped instances: {ids}")
    else:
        logger.info("No running Dev instances found.")

def start_dev_instances():
    """Starts EC2 Intances tagged Environment=Dev"""
    logger.info("Starting Dev EC2 Instances...")
    filters = [{'Name': 'tag:Environment', 'Values': ['Dev']}, {'Name': 'instance-state-name', 'Values': ['stopped']}]
    instances = ec2.describe_instances(Filters=filters)
    ids = [i['InstanceId'] for r in instances['Reservations'] for i in r['Instances']]
    
    if ids:
        ec2.start_instances(InstanceIds=ids)
        logger.info(f"Started instances: {ids}")

def cleanup_orphaned_resources():
    """Deletes available volumes and unassociated EIPs."""
    logger.info("Cleaning up orphaned resources...")
    
    # EBS Volumes
    volumes = ec2.describe_volumes(Filters=[{'Name': 'status', 'Values': ['available']}])
    for vol in volumes['Volumes']:
        vid = vol['VolumeId']
        # Check for protection tag
        tags = {t['Key']: t['Value'] for t in vol.get('Tags', [])}
        if tags.get('DoNotDelete') != 'true':
            ec2.delete_volume(VolumeId=vid)
            logger.info(f"Deleted orphaned volume: {vid}")

    # Elastic IPs
    eips = ec2.describe_addresses()
    for eip in eips['Addresses']:
        if 'AssociationId' not in eip:
            alloc_id = eip['AllocationId']
            ec2.release_address(AllocationId=alloc_id)
            logger.info(f"Released orphaned EIP: {alloc_id}")

def stop_dev_rds():
    """Stops RDS Instances tagged Environment=Dev"""
    logger.info("Stopping Dev RDS Instances...")
    dbs = rds.describe_db_instances()
    for db in dbs['DBInstances']:
        db_id = db['DBInstanceIdentifier']
        status = db['DBInstanceStatus']
        
        arn = db['DBInstanceArn']
        tags = rds.list_tags_for_resource(ResourceName=arn)['TagList']
        # Robust tag checking: strip whitespace
        env_tag = next((t['Value'].strip() for t in tags if t['Key'].strip() == 'Environment'), None)

        if env_tag == 'Dev' and status == 'available':
            rds.stop_db_instance(DBInstanceIdentifier=db_id)
            logger.info(f"Stopped RDS: {db_id}")

def start_dev_rds():
    """Starts RDS Instances tagged Environment=Dev"""
    logger.info("Starting Dev RDS Instances...")
    dbs = rds.describe_db_instances()
    for db in dbs['DBInstances']:
        db_id = db['DBInstanceIdentifier']
        status = db['DBInstanceStatus']
        
        arn = db['DBInstanceArn']
        tags = rds.list_tags_for_resource(ResourceName=arn)['TagList']
        # Robust tag checking: strip whitespace
        env_tag = next((t['Value'].strip() for t in tags if t['Key'].strip() == 'Environment'), None)

        if env_tag == 'Dev' and status == 'stopped':
            rds.start_db_instance(DBInstanceIdentifier=db_id)
            logger.info(f"Started RDS: {db_id}")
