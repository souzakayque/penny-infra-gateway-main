terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Estado remoto: sem isso o runner do CI perde o estado e recria a API a cada deploy.
  backend "s3" {
    bucket       = "penny-infra-s3-general-state"
    key          = "gtw-main/dev/terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region
}
