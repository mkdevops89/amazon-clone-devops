import boto3
import logging
import json

import os

# Setup Logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

ec2 = boto3.client('ec2')
ssm = boto3.client('ssm')
sns = boto3.client('sns')

SNS_TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN')

def lambda_handler(event, context):
    """
    The Auto-Healer:
    Triggered by CloudWatch Alarms via SNS or EventBridge.
    """
    logger.info(f"Received event: {json.dumps(event)}")
    
    try:
        if 'Records' in event:
            message = json.loads(event['Records'][0]['Sns']['Message'])
            alarm_name = message['AlarmName']
            state_reason = message['NewStateReason']
            logger.info(f"Alarm: {alarm_name}, Reason: {state_reason}")
            
            if "DiskSpace" in alarm_name:
                instance_id = parse_instance_id(message)
                if instance_id:
                    remediate_disk_space(instance_id)
            
        elif 'detail-type' in event and event['detail-type'] == 'AWS API Call via CloudTrail':
             event_name = event['detail']['eventName']
             if event_name == 'AuthorizeSecurityGroupIngress':
                 check_security_group_compliance(event['detail'])

    except Exception as e:
        logger.error(f"Error processing event: {e}")
        raise e

def parse_instance_id(message):
    """Extracts InstanceId from CloudWatch Alarm message."""
    metrics = message['Trigger']['Dimensions']
    for m in metrics:
        if m['name'] == 'InstanceId':
            return m['value']
    return None

def remediate_disk_space(instance_id):
    """Cleans /tmp and docker prune via SSM."""
    logger.info(f"Remediating Disk Space on {instance_id}...")
    
    commands = [
        "rm -rf /tmp/*",
        "docker system prune -f"
    ]
    
    response = ssm.send_command(
        InstanceIds=[instance_id],
        DocumentName="AWS-RunShellScript",
        Parameters={'commands': commands}
    )
    cmd_id = response['Command']['CommandId']
    logger.info(f"SSM Command Sent: {cmd_id}")
    
    publish_alert("Auto-Healer: Disk Space Cleaned", f"Executed cleanup on instance {instance_id}. Command ID: {cmd_id}")

def check_security_group_compliance(detail):
    """Revokes 0.0.0.0/0 on Port 22."""
    sg_id = detail['requestParameters']['groupId']
    items = detail['requestParameters']['ipPermissions']['items']
    
    for item in items:
        from_port = item.get('fromPort')
        to_port = item.get('toPort')
        
        if from_port == 22 or (from_port <= 22 and to_port >= 22):
            for ip_range in item.get('ipRanges', {}).get('items', []):
                if ip_range['cidrIp'] == '0.0.0.0/0':
                    logger.warning(f"SECURITY VIOLATION: Port 22 open to world on {sg_id}. Revoking...")
                    revoke_rule(sg_id, item)

def revoke_rule(sg_id, ip_permission):
    """Revokes the specific ingress rule."""
    ec2.revoke_security_group_ingress(
        GroupId=sg_id,
        IpPermissions=[ip_permission]
    )
    logger.info(f"Revoked bad rule on {sg_id}")
    publish_alert("Auto-Healer: Security Rule Revoked", f"Revoked 0.0.0.0/0 access on Port 22 for Security Group {sg_id}.")

def publish_alert(subject, message):
    """Publishes a message to the SNS Topic."""
    if SNS_TOPIC_ARN:
        sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject=subject,
            Message=message
        )
        logger.info(f"Published SNS Alert: {subject}")
    else:
        logger.warning("SNS_TOPIC_ARN not set. Skipping alert.")
