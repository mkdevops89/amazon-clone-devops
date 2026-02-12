import boto3
import json

def lambda_handler(event, context):
    action = event.get('action', 'status')
    eks = boto3.client('eks')
    cluster_name = 'amazon-cluster'
    
    # Get node groups
    nodegroups = eks.list_nodegroups(clusterName=cluster_name)['nodegroups']
    
    results = []
    
    for ng in nodegroups:
        if action == 'stop':
            eks.update_nodegroup_config(
                clusterName=cluster_name,
                nodegroupName=ng,
                scalingConfig={'desiredSize': 0}
            )
            results.append(f"Stopped {ng}")
        elif action == 'start':
            eks.update_nodegroup_config(
                clusterName=cluster_name,
                nodegroupName=ng,
                scalingConfig={'desiredSize': 2}
            )
            results.append(f"Started {ng}")
        else:
            desc = eks.describe_nodegroup(clusterName=cluster_name, nodegroupName=ng)
            size = desc['nodegroup']['scalingConfig']['desiredSize']
            results.append(f"Nodegroup {ng} current size: {size}")
            
    return {
        'statusCode': 200,
        'body': json.dumps({'message': results})
    }
