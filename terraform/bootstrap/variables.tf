variable "aws_region" {
  type        = string
  default     = "eu-west-1"
  description = "AWS region for all bootstrap resources"
}

variable "project_name" {
  type        = string
  default     = "order-processing-system"
  description = "Used as prefix for S3 bucket names"
}

variable "github_org" {
  type        = string
  description = "GitHub username or org"
}

variable "github_repo" {
  type        = string
  description = "GitHub repo name"
}
