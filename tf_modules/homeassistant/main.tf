module "cloudflare" {
  source = "./submodules/cloudflare"

  cloudflare_zone       = var.cloudflare.zone
  cloudflare_zone_id    = var.cloudflare.zone_id
  cloudflare_account_id = var.cloudflare.account_id
  tunnel_name           = "homeassistant"

  idps = {
    otp = {
      type   = "onetimepin"
      config = {}
    }
  }

  tunnel_config = {
    homeassistant = {
      path             = ""
      service          = var.cloudflare.tunnel_config.service
      enable_401       = true
      session_duration = "15m"
      http_only        = true
      allowed_idps     = ["otp"]
      access_rules = {
        AllowAWSLambda = {
          service_auth = true
          include = {
            country = [local.aws_region_country]
          }
          require = {}
        }
        AllowOTPLogin = {
          service_auth = false
          include = {
            email = var.cloudflare.tunnel_config.mail
          }
          require = {
            country = var.cloudflare.tunnel_config.country
          }
        }
      }
      origin_request = {
        no_tls_verify    = true
        http_host_header = split("/", var.cloudflare.tunnel_config.service)[2]
      }
    }
  }
}

module "iam" {
  source = "./submodules/iam"

  name        = "LambdaExecution"
  description = "Default Lambda execution role"

  policy_document = {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals = {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }

  policy = {
    effect      = "Allow"
    resource    = "*"
    action = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "ssm:Describe*",
      "ssm:Get*",
      "ssm:List*"
    ]
  }
}

module "connector" {
  source   = "./submodules/lambda"

  create_url      = false

  lambda_function = {
    name              = "${var.connector.lambda_function.name}-connector"
    description       = "Relays Alexa voice commands to homeassistant"
    function_version  = "1.0.0"
    source_dir        = var.connector.lambda_function.source_dir
    iam_role          = module.iam.iam_role_name
    handler           = "main.lambda_handler"
    runtime           = "python3.9"
    ephemeral_storage = 512
    memory_size       = 128
    timeout           = 10
    env_vars          = {
      APP_CONFIG_PATH = "/ha-alexa/"
    }
  }

  trigger         = {
    name               = "AllowExecutionFromAlexa"
    action             = "lambda:InvokeFunction"
    principal          = "alexa-connectedhome.amazon.com"
    event_source_token = var.connector.alexa_skill_token
  }

  app_config      = {
    name        = "/ha-alexa/appConfig"
    description = "App config for lambda functions connecting alexa and homeassistant"
    value       = <<EOF
{
  "CF_CLIENT_ID": "${module.cloudflare.service_tokens["homeassistant"].client_id}",
  "CF_CLIENT_SECRET": "${module.cloudflare.service_tokens["homeassistant"].client_secret}",
  "HA_BASE_URL": "${module.cloudflare.url}",
  "HA_TOKEN": "${var.connector.app_config.ha_access_token}",
  "WRAPPER_SECRET": "${var.connector.app_config.wrapper_secret}"
}
EOF
  }
}

module "wrapper" {
  source   = "./submodules/lambda"

  lambda_function = {
    name              = "${var.wrapper.lambda_function.name}-wrapper"
    description       = "Handles authentication for the Alexa connector"
    function_version  = "1.0.0"
    source_dir        = var.wrapper.lambda_function.source_dir
    iam_role          = module.iam.iam_role_name
    handler           = "main.lambda_handler"
    runtime           = "python3.9"
    ephemeral_storage = 512
    memory_size       = 128
    timeout           = 10
    env_vars          = {
      APP_CONFIG_PATH = "/ha-alexa/"
    }
  }

  trigger         = null
  app_config      = null
  create_url      = true
}
