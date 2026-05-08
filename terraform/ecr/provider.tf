terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # ──────────────────────────────────────────────────────────────────
  # Remote state — ask your Infrastructure Engineer-3 to create this
  # S3 bucket + DynamoDB table once before running terraform init.
  # ──────────────────────────────────────────────────────────────────
  backend "s3" {
    bucket         = "petclinic-tf-state-prod-135728714831"          # change to your shared bucket name
    key            = "petclinic/ecr/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "petclinic-tf-locks"          # for state locking
    encrypt        = true

    # 2. Use the new locking parameter
    use_lockfile   = true

    # 3. Explicitly tell the backend which profile to use
    profile        = "suganya"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "spring-petclinic"
      ManagedBy = "terraform"
      Team      = "cicd"
    }
  }
}

# Used in outputs to derive the ECR registry URL
data "aws_caller_identity" "current" {}
