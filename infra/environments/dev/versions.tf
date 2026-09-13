terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend remoto (S3 + DynamoDB lock) é uma pendência — ver seção 14 do plano.
  # backend "s3" {}
}

provider "aws" {
  region = var.aws_region
}
