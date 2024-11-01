variable "lambda_function" {
  description = "Configuration for the lambda function"
  type        = object({
    name              = string
    description       = optional(string, null)
    source_dir        = string
    handler           = optional(string, "main.lambda_handler")
    runtime           = string
    iam_role          = string
    memory_size       = optional(number, 128)
    ephemeral_storage = optional(number, 512)
    timeout           = optional(number, 3)
    env_vars          = optional(map(string), {})
    function_version  = string
  })
}

variable "trigger" {
  description = "Trigger for the lambda function"
  type        = object({
    name               = string
    action             = string
    principal          = string
    event_source_token = string
  })
  default = null
}

variable "app_config" {
  description  = "SSM secure string config"
  type         = object({
    name        = string
    description = string
    value       = string
  })
  default = null
}

variable "create_url" {
  description = "Trigger to create a function URL"
  type        = bool
  default     = false
}
