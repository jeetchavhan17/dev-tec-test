# DevOps Tech Test - Terraform + ECS (EC2) + MongoDB sample

This repo contains:
- a small Node.js app (docker/app)
- Dockerfile to build the image
- Terraform code (terraform/) that deploys:
  - S3/DynamoDB backend (needs to be created/set)
  - VPC, ECS cluster (EC2), Launch Template + ASG
  - ECR repository
  - ALB and Target Group
  - ECS task definition + service
- README_TERRAFORM.md (terraform specific steps)
- comparison.md (ECS EC2 vs Fargate)

---

## Pre-requisites (local machine)
- AWS CLI v2 configured (`aws configure`) or environment credentials
- Docker (to build image)
- Terraform v1.1+
- jq (optional, for parsing outputs)

---

## 1) Prepare Terraform backend (S3 + DynamoDB)
You need an S3 bucket and a DynamoDB table for state locking. Create them once (example):

```bash
# choose bucket/table names
export TF_BUCKET="my-terraform-state-<your-id>"
export TF_LOCK_TABLE="terraform-lock-table-<your-id>"
aws s3 mb s3://$TF_BUCKET --region us-east-1

aws dynamodb create-table \
  --table-name $TF_LOCK_TABLE \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region us-east-1

---

## 2) Build Docker image and push to ECR

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account>.dkr.ecr.us-east-1.amazonaws.com
# create repo (the terraform will also create it, but you can create manually to push)
aws ecr create-repository --repository-name devops-sample-app-dev --region us-east-1 || true

# tag & push
docker build -t devops-sample-app:latest ./docker
docker tag devops-sample-app:latest <account>.dkr.ecr.us-east-1.amazonaws.com/devops-sample-app-dev:latest
docker push <account>.dkr.ecr.us-east-1.amazonaws.com/devops-sample-app-dev:latest

# Image URI to use in terraform:
export APP_IMAGE="957551240565.dkr.ecr.us-east-1.amazonaws.com/devops-sample-app-dev:latest"

---

## 3) Create (or get) MongoDB connection string

- create a free cluster on MongoDB Atlas and get the connection URI, e.g.:
  mongodb+srv://user:password@cluster0.abcd.mongodb.net/mydb?retryWrites=true&w=majority
- For this exercise you can use Atlas and whitelist 0.0.0.0/0 (not for prod).
- Save the URI; we'll pass it as mongodb_uri variable to terraform.

---

## 4) Terraform: init / plan / apply
cd terraform

# Initialize with backend config (or edit backend.tf)
terraform init \
  -backend-config="bucket=$TF_BUCKET" \
  -backend-config="key=dev/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="dynamodb_table=$TF_LOCK_TABLE"

terraform plan -var="tfstate_bucket=$TF_BUCKET" -var="tfstate_lock_table=$TF_LOCK_TABLE" \
  -var="app_image=$APP_IMAGE" \
  -var="mongodb_uri='mongodb+srv://user:pass@.../testdb?retryWrites=true&w=majority'"

terraform apply -var="tfstate_bucket=$TF_BUCKET" -var="tfstate_lock_table=$TF_LOCK_TABLE" \
  -var="app_image=$APP_IMAGE" \
  -var="mongodb_uri='mongodb+srv://user:pass@.../testdb?retryWrites=true&w=majority'" -auto-approve

---

## 5) How to access the application
      terraform output -raw alb_dns

---







