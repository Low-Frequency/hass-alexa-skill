data "aws_iam_role" "role" {
  name = var.lambda_function.iam_role
}

resource "aws_lambda_function" "lambda" {
  filename          = "${var.lambda_function.source_dir}/lambda.zip"
  package_type      = "Zip"
  function_name     = var.lambda_function.name
  description       = var.lambda_function.description
  handler           = var.lambda_function.handler
  runtime           = var.lambda_function.runtime
  role              = data.aws_iam_role.role.arn
  memory_size       = var.lambda_function.memory_size
  timeout           = var.lambda_function.timeout

  source_code_hash = filebase64sha256("${var.lambda_function.source_dir}/lambda.zip")

  ephemeral_storage {
    size = var.lambda_function.ephemeral_storage
  }

  dynamic "environment" {
    for_each = length(var.lambda_function.env_vars) > 0 ? [1] : []

    content {
      variables = var.lambda_function.env_vars
    }
  }

  tags = {
    ManagedBy = "Terraform"
    Version   = var.lambda_function.function_version
  }
}

resource "aws_lambda_permission" "trigger" {
  for_each = var.trigger != null ? toset(["1"]) : []

  function_name      = aws_lambda_function.lambda.function_name
  statement_id       = var.trigger.name
  action             = var.trigger.action
  principal          = var.trigger.principal
  event_source_token = var.trigger.event_source_token
}

resource "aws_lambda_function_url" "url" {
  for_each = var.create_url ? toset(["1"]) : []

  authorization_type = "NONE"
  function_name      = aws_lambda_function.lambda.function_name
}

resource "aws_ssm_parameter" "app_config" {
  for_each = var.app_config != null ? toset(["1"]) : []

  name        = var.app_config.name
  type        = "SecureString"
  description = var.app_config.description
  value       = var.app_config.value
  tier        = "Standard"

  tags = {
    ManagedBy = "Terraform"
  }
}
