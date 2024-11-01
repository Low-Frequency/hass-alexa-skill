output "url" {
  description = "URL to homeassistant"
  value       = cloudflare_record.dns_record.hostname
}

output "service_tokens" {
  description = "Map of service tokens that have been created"
  value = merge(
    [for key, value in var.tunnel_config :
      {for name, rule in value.access_rules :
        key => {
          client_id     = cloudflare_zero_trust_access_service_token.service_token[key].client_id
          client_secret = cloudflare_zero_trust_access_service_token.service_token[key].client_secret
        } if rule.service_auth
      }
    ]...
  )
  sensitive = true
}

output "tunnel_token" {
  value     = cloudflare_zero_trust_tunnel_cloudflared.cloudflare_tunnel.tunnel_token
  sensitive = true
}
