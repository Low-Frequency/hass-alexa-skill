resource "cloudflare_zero_trust_access_identity_provider" "idp" {
  for_each = var.idps

  zone_id = var.cloudflare_zone_id
  name    = each.key
  type    = each.value.type

  dynamic "config" {
    for_each = each.value.config != null ? [1] : []

    content {
      client_id     = each.value.config.client_id
      client_secret = each.value.config.client_secret
      directory_id  = each.value.config.directory_id
    }
  }
}
