variable "cloudflare_zone" {
  description = "Domain used to expose the VM instance to the Internet"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Zone ID for your domain"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Account ID for your Cloudflare account"
  type        = string
  sensitive   = true
}

variable "tunnel_name" {
  description = "Name of the tunnel"
  type        = string
}

variable "tunnel_config" {
  description = <<-EOD
    Ingress rules for the cloudflare tunnel
    The key will be used as the hostname
EOD
  type = map(object({
    path                 = optional(string, "")
    service              = string
    enable_401           = optional(bool, true)
    session_duration     = optional(string, "6h")
    http_only            = optional(bool, false)
    allowed_idps         = optional(set(string), [])
    access_rules = map(object({
      service_auth = optional(bool, false)
      include = object({
        email        = optional(set(string), [])
        email_domain = optional(set(string), [])
        country      = optional(set(string), [])
        everyone     = optional(bool, false)
      })
      require = optional(object({
        email        = optional(set(string), [])
        email_domain = optional(set(string), [])
        country      = optional(set(string), [])
      }), {})
    }))
    origin_request = optional(object({
      no_tls_verify    = optional(bool, true)
      http_host_header = optional(string, "")
      }), {
      no_tls_verify    = true
      http_host_header = ""
    })
  }))
  default = {}
}

variable "idps" {
  description = "Allowed IDPs for all access applications"
  type = map(object({
    type = string
    config = optional(object({
      client_id     = optional(string, null)
      client_secret = optional(string, null)
      directory_id  = optional(string, null)
    }), null)
  }))
  default = {
    otp = {
      type = "onetimepin"
    }
  }
}
