output "alexa_skill_configuration" {
  description = "Overview over the necessary Alexa skill configuration"
  value = {
    smart_home = {
      default_endpoint = module.homeassistant.connector_arn
    }
    account_linking = {
      web_authorization_url = "https://${module.homeassistant.ha_web_url}/auth/authorize"
      access_token_uri      = module.homeassistant.wrapper_url
      client_id             = var.aws_region == "eu-west-1" ? "https://layla.amazon.com/" : "https://pitangui.amazon.com/"
      your_secret           = var.wrapper_secret
      authentication_scheme = "Credentials in request body"
      scope                 = "smart_home"
    }
  }
}

output "cf_tunnel_install_commands" {
  description = "Short summary of install commands"
  value       = {
    download  = "curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb"
    install   = "sudo dpkg -i cloudflared.deb"
    configure = "sudo cloudflared service install ${module.homeassistant.cf_tunnel_token}"
  }
}
