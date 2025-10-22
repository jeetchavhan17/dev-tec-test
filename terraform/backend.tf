terraform {
  backend "s3" {
    bucket         = "my-terraform-state-957551240565"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks-957551240565"
    encrypt        = true
  }
}
