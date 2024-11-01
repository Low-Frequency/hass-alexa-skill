output "lambda_arn" {
  description = "ARN of the created lambda function"
  value       = aws_lambda_function.lambda.arn
}

output "lambda_url" {
  description = "ARN of the created lambda function"
  value       = var.create_url ? aws_lambda_function_url.url["1"].function_url : null
}
