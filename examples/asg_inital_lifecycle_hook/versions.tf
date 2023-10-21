terraform {
  required_version = ">= 0.12.31"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }

    null = {
      source  = "hashicorp/null"
      version = ">= 2.0"
    }

    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}
