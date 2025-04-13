terraform {
  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = "= 2.7.0"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "= 5.94.0"
    }

    external = {
      source  = "hashicorp/external"
      version = "= 2.3.4"
    }

    null = {
      source  = "hashicorp/null"
      version = "= 3.2.3"
    }

    random = {
      source  = "hashicorp/random"
      version = "= 3.7.1"
    }
  }
}

# provider "aws" {
#   region = "ap-south-1" 
# }
