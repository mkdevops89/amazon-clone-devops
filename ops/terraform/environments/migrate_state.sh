#!/bin/bash
set -e

echo "=========================================================="
echo "Phase 19: Surgical Terragrunt State Migration"
echo "=========================================================="
echo "WARNING: This script manipulates live AWS state."
echo "If this fails, the infrastructure will be out of sync."

cd ops/terraform

# 1. Pull the master state one last time for safety
echo "=> Pulling latest Master State..."
cd aws 
terraform init -reconfigure
terraform state pull > ../environments/dev/master.tfstate
cd ../environments/dev

# 2. Define the Mapping Logic
# We are mathematically slicing the master.tfstate into 6 pieces.
# Format: terraform state mv -state=master.tfstate -state-out=TARGET_DIR/terraform.tfstate SOURCE TARGET

echo "=> Slicing the S3 Storage Module..."
mkdir -p s3
terraform state mv -state=master.tfstate -state-out=s3/terraform.tfstate "random_id.image_bucket_suffix" "random_id.image_bucket_suffix" || true
terraform state mv -state=master.tfstate -state-out=s3/terraform.tfstate "aws_s3_bucket.product_images" "aws_s3_bucket.product_images" || true
terraform state mv -state=master.tfstate -state-out=s3/terraform.tfstate "aws_s3_bucket_public_access_block.product_images_public" "aws_s3_bucket_public_access_block.product_images_public" || true
terraform state mv -state=master.tfstate -state-out=s3/terraform.tfstate "aws_s3_bucket_policy.product_images_open_read" "aws_s3_bucket_policy.product_images_open_read" || true
terraform state mv -state=master.tfstate -state-out=s3/terraform.tfstate "aws_s3_bucket_cors_configuration.product_images_cors" "aws_s3_bucket_cors_configuration.product_images_cors" || true

terraform state mv -state=master.tfstate -state-out=s3/terraform.tfstate "random_id.reports_bucket_suffix" "random_id.reports_bucket_suffix" || true
terraform state mv -state=master.tfstate -state-out=s3/terraform.tfstate "aws_s3_bucket.reports" "aws_s3_bucket.reports" || true
terraform state mv -state=master.tfstate -state-out=s3/terraform.tfstate "aws_s3_bucket_server_side_encryption_configuration.reports_encryption" "aws_s3_bucket_server_side_encryption_configuration.reports_encryption" || true
terraform state mv -state=master.tfstate -state-out=s3/terraform.tfstate "aws_s3_bucket_public_access_block.reports_public_access" "aws_s3_bucket_public_access_block.reports_public_access" || true

terraform state mv -state=master.tfstate -state-out=s3/terraform.tfstate "random_id.bucket_suffix" "random_id.bucket_suffix" || true
terraform state mv -state=master.tfstate -state-out=s3/terraform.tfstate "aws_s3_bucket.security_evidence" "aws_s3_bucket.security_evidence" || true
terraform state mv -state=master.tfstate -state-out=s3/terraform.tfstate "aws_s3_bucket_object_lock_configuration.evidence_lock" "aws_s3_bucket_object_lock_configuration.evidence_lock" || true
terraform state mv -state=master.tfstate -state-out=s3/terraform.tfstate "aws_s3_bucket_versioning.evidence_versioning" "aws_s3_bucket_versioning.evidence_versioning" || true
terraform state mv -state=master.tfstate -state-out=s3/terraform.tfstate "aws_s3_bucket_server_side_encryption_configuration.evidence_encryption" "aws_s3_bucket_server_side_encryption_configuration.evidence_encryption" || true
terraform state mv -state=master.tfstate -state-out=s3/terraform.tfstate "aws_s3_bucket_public_access_block.evidence_privacy" "aws_s3_bucket_public_access_block.evidence_privacy" || true
terraform state mv -state=master.tfstate -state-out=s3/terraform.tfstate "aws_s3_bucket_policy.cloudtrail_write_policy" "aws_s3_bucket_policy.cloudtrail_write_policy" || true


echo "=> Slicing the Cognito Identity Module..."
mkdir -p cognito
terraform state mv -state=master.tfstate -state-out=cognito/terraform.tfstate "aws_cognito_user_pool.pool" "aws_cognito_user_pool.pool" || true
terraform state mv -state=master.tfstate -state-out=cognito/terraform.tfstate "aws_cognito_user_pool_domain.main" "aws_cognito_user_pool_domain.main" || true
terraform state mv -state=master.tfstate -state-out=cognito/terraform.tfstate "aws_cognito_user_pool_client.client" "aws_cognito_user_pool_client.client" || true
terraform state mv -state=master.tfstate -state-out=cognito/terraform.tfstate "aws_ssm_parameter.cognito_user_pool_id" "aws_ssm_parameter.cognito_user_pool_id" || true
terraform state mv -state=master.tfstate -state-out=cognito/terraform.tfstate "aws_ssm_parameter.cognito_app_client_id" "aws_ssm_parameter.cognito_app_client_id" || true
terraform state mv -state=master.tfstate -state-out=cognito/terraform.tfstate "aws_ssm_parameter.cognito_domain" "aws_ssm_parameter.cognito_domain" || true


echo "=> Slicing the Security & Audit Module..."
mkdir -p security
terraform state mv -state=master.tfstate -state-out=security/terraform.tfstate "aws_securityhub_account.portfolio_soc" "aws_securityhub_account.portfolio_soc" || true
terraform state mv -state=master.tfstate -state-out=security/terraform.tfstate "aws_securityhub_standards_subscription.fsbp" "aws_securityhub_standards_subscription.fsbp" || true
terraform state mv -state=master.tfstate -state-out=security/terraform.tfstate "aws_guardduty_detector.primary" "aws_guardduty_detector.primary" || true
terraform state mv -state=master.tfstate -state-out=security/terraform.tfstate "aws_cloudtrail.account_audit" "aws_cloudtrail.account_audit" || true


echo "=> Slicing the IAM Roles Module..."
mkdir -p iam
terraform state mv -state=master.tfstate -state-out=iam/terraform.tfstate "aws_iam_policy.cost_explorer_policy" "aws_iam_policy.cost_explorer_policy" || true
terraform state mv -state=master.tfstate -state-out=iam/terraform.tfstate "aws_iam_policy.bedrock_invoke_policy" "aws_iam_policy.bedrock_invoke_policy" || true


echo "=> Slicing the Serverless Compute Module..."
mkdir -p serverless
terraform state mv -state=master.tfstate -state-out=serverless/terraform.tfstate "aws_iam_role.lambda_exec" "aws_iam_role.lambda_exec" || true
terraform state mv -state=master.tfstate -state-out=serverless/terraform.tfstate "aws_iam_policy.lambda_policy" "aws_iam_policy.lambda_policy" || true
terraform state mv -state=master.tfstate -state-out=serverless/terraform.tfstate "aws_iam_role_policy_attachment.lambda_attach" "aws_iam_role_policy_attachment.lambda_attach" || true
terraform state mv -state=master.tfstate -state-out=serverless/terraform.tfstate "aws_sns_topic.alerts" "aws_sns_topic.alerts" || true
terraform state mv -state=master.tfstate -state-out=serverless/terraform.tfstate "aws_lambda_function.cost_optimizer" "aws_lambda_function.cost_optimizer" || true
terraform state mv -state=master.tfstate -state-out=serverless/terraform.tfstate "aws_cloudwatch_event_rule.nightly_stop" "aws_cloudwatch_event_rule.nightly_stop" || true
terraform state mv -state=master.tfstate -state-out=serverless/terraform.tfstate "aws_cloudwatch_event_target.trigger_stop" "aws_cloudwatch_event_target.trigger_stop" || true
terraform state mv -state=master.tfstate -state-out=serverless/terraform.tfstate "aws_lambda_permission.allow_eventbridge" "aws_lambda_permission.allow_eventbridge" || true

terraform state mv -state=master.tfstate -state-out=serverless/terraform.tfstate "aws_lambda_function.auto_healer" "aws_lambda_function.auto_healer" || true
terraform state mv -state=master.tfstate -state-out=serverless/terraform.tfstate "aws_cloudwatch_event_rule.morning_start" "aws_cloudwatch_event_rule.morning_start" || true
terraform state mv -state=master.tfstate -state-out=serverless/terraform.tfstate "aws_cloudwatch_event_target.trigger_start" "aws_cloudwatch_event_target.trigger_start" || true
terraform state mv -state=master.tfstate -state-out=serverless/terraform.tfstate "aws_lambda_permission.allow_eventbridge_start" "aws_lambda_permission.allow_eventbridge_start" || true


echo "=> Slicing the VPC Networking Module..."
mkdir -p vpc
terraform state mv -state=master.tfstate -state-out=vpc/terraform.tfstate "module.vpc" "module.vpc" || true


echo "=> Slicing the EKS Compute Module..."
mkdir -p eks
# Move the EKS module itself
terraform state mv -state=master.tfstate -state-out=eks/terraform.tfstate "module.eks" "module.eks" || true
# Move Security Groups
terraform state mv -state=master.tfstate -state-out=eks/terraform.tfstate "aws_security_group.db_sg" "aws_security_group.db_sg" || true
terraform state mv -state=master.tfstate -state-out=eks/terraform.tfstate "aws_security_group.redis_sg" "aws_security_group.redis_sg" || true
terraform state mv -state=master.tfstate -state-out=eks/terraform.tfstate "aws_security_group.mq_sg" "aws_security_group.mq_sg" || true
# Move RDS
terraform state mv -state=master.tfstate -state-out=eks/terraform.tfstate "module.db" "module.db" || true
# Move Redis
terraform state mv -state=master.tfstate -state-out=eks/terraform.tfstate "module.elasticache" "module.elasticache" || true
# Move RabbitMQ
terraform state mv -state=master.tfstate -state-out=eks/terraform.tfstate "aws_mq_broker.rabbitmq" "aws_mq_broker.rabbitmq" || true
terraform state mv -state=master.tfstate -state-out=eks/terraform.tfstate "random_password.mq_password" "random_password.mq_password" || true
# Move Bastion
terraform state mv -state=master.tfstate -state-out=eks/terraform.tfstate "tls_private_key.ansible_bastion_key" "tls_private_key.ansible_bastion_key" || true
terraform state mv -state=master.tfstate -state-out=eks/terraform.tfstate "aws_key_pair.ansible_bastion_keypair" "aws_key_pair.ansible_bastion_keypair" || true
terraform state mv -state=master.tfstate -state-out=eks/terraform.tfstate "aws_security_group.bastion_sg" "aws_security_group.bastion_sg" || true
terraform state mv -state=master.tfstate -state-out=eks/terraform.tfstate "aws_instance.ansible_bastion" "aws_instance.ansible_bastion" || true

echo "=========================================================="
echo "Migration Script Generation Complete."
echo "Execute locally with: bash ops/terraform/environments/migrate_state.sh"
echo "=========================================================="
