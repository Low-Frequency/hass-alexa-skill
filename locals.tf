locals {
  cloudflare = {
    zone       = var.cloudflare_zone
    zone_id    = var.cloudflare_zone_id
    account_id = var.cloudflare_account_id
    aws_region = var.aws_region
    tunnel_config = {
      service = var.homeassistant_local_url
      access  = {
        country = var.allowed_countries
        mail    = var.allowed_mails
      }
    }
  }

  connector = {
    lambda_function = {
      name       = var.function_name
      source_dir = "src/connector"
    }
    alexa_skill_token = var.alexa_skill_token
    app_config = {
      ha_access_token  = var.ha_access_token
      wrapper_secret   = var.wrapper_secret
    }
  }

  wrapper = {
    lambda_function = {
      name       = var.function_name
      source_dir = "src/wrapper"
    }
  }
}
