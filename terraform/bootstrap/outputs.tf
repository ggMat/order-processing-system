output "role_arn" {
  value       = aws_iam_role.github_actions.arn
  description = "Paste this into GitHub repo secrets as AWS_ROLE_ARN"
}

output "tfstate_bucket_dev" {
  value       = module.tfstate_dev.s3_bucket_id
  description = "S3 bucket name for dev state"
}

output "tfstate_bucket_prod" {
  value       = module.tfstate_prod.s3_bucket_id
  description = "S3 bucket name for prod state"
}

output "dynamodb_lock_dev" {
  value       = aws_dynamodb_table.lock_dev.name
  description = "DynamoDB lock table for dev"
}

output "dynamodb_lock_prod" {
  value       = aws_dynamodb_table.lock_prod.name
  description = "DynamoDB lock table for prod"
}
