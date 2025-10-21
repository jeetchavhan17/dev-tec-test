variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "tfstate_bucket" {
  type = string
  description = "S3 bucket for terraform state"
}

variable "tfstate_lock_table" {
  type = string
  description = "DynamoDB table name for state locking"
}

variable "app_image" {
  type        = string
  description = "ECR image URI (e.g., <account>.dkr.ecr.<region>.amazonaws.com/repo:tag)"
}

variable "mongodb_uri" {
  type = string
  description = "MongoDB connection URI"
  sensitive = true
}

