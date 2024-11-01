### Creates a service token for authenticating
resource "cloudflare_zero_trust_access_service_token" "service_token" {
  for_each = toset(
    compact(
      flatten(
        [for key, value in var.tunnel_config :
          [for name, rule in value.access_rules :
            rule.service_auth ? key : null
          ]
        ]
      )
    )
  )

  name    = each.key
  zone_id = var.cloudflare_zone_id
}

### Creates an Access application to control who can connect
### Enables authentication for the tunneled service
resource "cloudflare_zero_trust_access_application" "access_application" {
  for_each = var.tunnel_config

  type                       = "self_hosted"
  zone_id                    = var.cloudflare_zone_id
  name                       = "Access application for ${each.key}.${var.cloudflare_zone}"
  domain                     = "${each.key}.${var.cloudflare_zone}"
  session_duration           = each.value.session_duration
  allowed_idps               = toset([for idp in each.value.allowed_idps : cloudflare_zero_trust_access_identity_provider.idp[idp].id])
  auto_redirect_to_identity  = length(each.value.allowed_idps) == 1 ? true : (length(each.value.allowed_idps) == 0 ? null : false)
  app_launcher_visible       = false
  service_auth_401_redirect  = each.value.enable_401
  http_only_cookie_attribute = each.value.http_only
}

### Creates an Access policy for the application
resource "cloudflare_zero_trust_access_policy" "access_policy" {
  ### The function creates a new map to loop over based on the access_rules in each tunnel_config
  #!  It takes every tunnel_config, loops over the access_rules inside and combines the keys
  #!  The value of the new key is the value of the resepective access_rule
  #!  To achieve that it creates a list of lists by looping over the tunnel_config
  #!  On each loop it creates the inner list by looping over the access_rules
  #!  The inner list contains simple maps with all access rules
  #!  After that it flattens the list, so the inner list will be combined into one
  #!  In the final step, it expands the elements inside into separate elements and merges them, resulting in a map
  for_each = merge(
    flatten(
      [for key, value in var.tunnel_config :
        [for name, rule in value.access_rules :
          {
            "${key}_${name}" = rule
          }
        ]
      ]
    )...
  )

  application_id = cloudflare_zero_trust_access_application.access_application[split("_", each.key)[0]].id
  zone_id        = var.cloudflare_zone_id
  name           = split("_", each.key)[1]

  ### precedence is calculated based on the positioning in the access_rules map
  #!  The function creates a similar map as in the for_each loop
  #!  It extracts the keys as a list if the key matches the current for_each loops key
  #!  After theat it gets the index of the current key and adds 1, resulting in a number starting at 1 for each tunnel_config element
  precedence = index(
    keys(
      merge(
        flatten(
          [for key, value in var.tunnel_config :
            [for name, rule in value.access_rules :
              {
                "${key}_${name}" = rule
              } if key == split("_", each.key)[0]
            ]
          ]
        )...
      )
    ), "${each.key}"
  ) + 1

  decision = each.value.service_auth ? "non_identity" : "allow"

  include {
    email         = length(each.value.include.email) > 0 ? each.value.include.email : null
    email_domain  = length(each.value.include.email_domain) > 0 ? each.value.include.email_domain : null
    geo           = length(each.value.include.country) > 0 ? each.value.include.country : null
    everyone      = each.value.include.everyone ? true : null
    service_token = each.value.service_auth ? [cloudflare_zero_trust_access_service_token.service_token[split("_", each.key)[0]].id] : null
  }

  dynamic "require" {
    for_each = provider::logic::exactly_one_true(
      [
        provider::logic::xor(each.value.service_auth, length(each.value.require.email) > 0),
        provider::logic::xor(each.value.service_auth, length(each.value.require.email_domain) > 0),
      ]
    ) || each.value.service_auth || length(each.value.require.country) > 0 ? [1] : []

    content {
      email         = length(each.value.require.email) > 0 ? each.value.require.email : null
      email_domain  = length(each.value.require.email_domain) > 0 ? each.value.require.email_domain : null
      geo           = length(each.value.require.country) > 0 ? each.value.require.country : null
      service_token = each.value.service_auth ? [cloudflare_zero_trust_access_service_token.service_token[split("_", each.key)[0]].id] : null
    }
  }
}
