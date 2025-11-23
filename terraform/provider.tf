terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
# Region: London (eu-west-2) selected for this demo
provider "aws" {
  region = "eu-west-2"
}