terraform {
  required_version = "~> 1.9"
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.40"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    logic = {
      source  = "logicorg/logic"
      version = "~> 0.1"
    }
  }
}
