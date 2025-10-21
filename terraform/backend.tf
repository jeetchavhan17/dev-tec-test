terraform {
  required_version = ">= 1.1.0"
  backend "s3" {
    bucket         = var.tfstate_bucket
    key            = "${var.environment}/terraform.tfstate"
    region         = var.aws_region
    dynamodb_table = var.tfstate_lock_table
    encrypt        = true
  }
}

