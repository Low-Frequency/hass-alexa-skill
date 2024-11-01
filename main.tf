module "homaeassistant" {
  source = "./tf_modules/homeassistant"

  cloudflare = local.cloudflare
  connector  = local.connector
  wrapper    = local.wrapper
}
