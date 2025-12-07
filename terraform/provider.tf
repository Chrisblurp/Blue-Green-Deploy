terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Optional: Uncomment to use S3 backend for remote state
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "ecs-bluegreen/terraform.tfstate"
  #   region         = "eu-central-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Environment = "production"
      Project     = "ecs-bluegreen"
      ManagedBy   = "Terraform"
    }
  }
}