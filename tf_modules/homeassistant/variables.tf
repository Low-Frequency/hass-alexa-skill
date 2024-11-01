variable "cloudflare" {
  description = "Configuration for the cloudflare tunnel"
  type = object({
    zone       = string
    zone_id    = string
    account_id = string
    aws_region = string
    tunnel_config = map(object({
      service = string
      access  = map(object({
        country = set(string)
        mail    = set(string)
      }))
    }))
  })
}

variable "connector" {
  description = "Configuration for the lambda connector"
  type = object({
    lambda_function = object({
      name              = string
      source_dir        = string
    })
    alexa_skill_token = optional(string, "")
    app_config = optional(object({
      cf_client_id     = string
      cf_client_secret = string
      ha_base_url      = string
      ha_access_token  = string
      wrapper_secret   = string
    }), {})
  })
}

variable "wrapper" {
  description = "Configuration for the lambda wrapper"
  type = object({
    lambda_function = object({
      name              = string
      description       = string
      source_dir        = string
    })
  })
}
