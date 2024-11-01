### Generates a 64-character secret for the tunnel
resource "random_id" "tunnel_secret" {
  byte_length = 64
}

### Creates a new tunnel
resource "cloudflare_zero_trust_tunnel_cloudflared" "cloudflare_tunnel" {
  account_id = var.cloudflare_account_id
  name       = var.tunnel_name
  secret     = random_id.tunnel_secret.b64_std
  config_src = "cloudflare"
}

### Creates the tunnel config
resource "cloudflare_zero_trust_tunnel_cloudflared_config" "tunnel_config" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.cloudflare_tunnel.id
  config {
    dynamic "ingress_rule" {
      for_each = var.tunnel_config

      content {
        hostname = "${ingress_rule.key}.${var.cloudflare_zone}"
        path     = ingress_rule.value.path
        service  = ingress_rule.value.service

        origin_request {
          no_tls_verify    = ingress_rule.value.origin_request.no_tls_verify
          http_host_header = ingress_rule.value.origin_request.http_host_header
        }
      }
    }
    ingress_rule {
      service = "http_status:404"
    }
  }
}

### Creates the CNAME record that routes ${var.subdomain}.${var.cloudflare_zone} to the tunnel
resource "cloudflare_record" "dns_record" {
  for_each = var.tunnel_config

  zone_id = var.cloudflare_zone_id
  name    = each.key
  content = cloudflare_zero_trust_tunnel_cloudflared.cloudflare_tunnel.cname
  type    = "CNAME"
  proxied = true
}
