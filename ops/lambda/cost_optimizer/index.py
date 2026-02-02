import boto3
import logging
import os
from datetime import datetime

# Setup Logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Clients
ec2 = boto3.client('ec2')
asg = boto3.client('autoscaling')
eks = boto3.client('eks')

def lambda_handler(event, context):
    """
    The Cost Terminator:
    Triggered by EventBridge Rule (e.g., "Nightly Stop" or "Morning Start").
    Event Payload: {"action": "stop"} or {"action": "start"}
    """
    action = event.get('action', 'stop')
    logger.info(f"Received action: {action}")

    if action == 'stop':
        scale_down_eks_nodes()
        stop_dev_instances()
        cleanup_orphaned_resources()
    elif action == 'start':
        restore_eks_nodes()
        start_dev_instances()
    
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
    """Restores EKS Node Groups to default size (e.g., 2)."""
    logger.info("Restoring EKS Node Groups...")
    cluster_name = os.environ.get('CLUSTER_NAME', 'amazon-cluster')
    
    try:
        nodegroups = eks.list_nodegroups(clusterName=cluster_name)['nodegroups']
        for ng in nodegroups:
            # In a real scenario, read from DynamoDB/Tags. Here we default to 2.
            eks.update_nodegroup_config(
                clusterName=cluster_name,
                nodegroupName=ng,
                scalingConfig={'minSize': 2, 'desiredSize': 2}
            )
            logger.info(f"Restored {ng} to size 2")
    except Exception as e:
        logger.error(f"Failed to restore EKS: {e}")

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
