output "connector_arn" {
  description = "ARN of the connector"
  value       = module.connector.lambda_arn
}

output "wrapper_url" {
  description = "Function URL of the wrapper"
  value       = module.wrapper.lambda_url
}

output "cf_tunnel_token" {
  description = "Token to be used to configure cloudflared"
  value       = module.cloudflare.tunnel_token
}

output "ha_web_url" {
  description = "Public HA endpoint"
  value       = module.cloudflare.url
}
