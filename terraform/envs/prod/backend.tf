terraform {
  backend "s3" {
    bucket         = "order-processing-system-tfstate-prod"
    key            = "order-processing-system/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "order-processing-system-tfstate-lock-prod"
    encrypt        = true
  }
}
