variable "function_name" {}
variable "filename" {}
variable "handler" {}
variable "runtime" {}
variable "role_arn" {}
variable "environment_variables" {}
variable "vpc_config" {}
variable "layer_arns" {}

resource "aws_lambda_function" "function" {
  function_name    = var.function_name
  filename         = var.filename
  handler          = var.handler
  runtime          = var.runtime
  role             = var.role_arn
  timeout          = 30
  source_code_hash = filebase64sha256(var.filename)

  vpc_config {
    subnet_ids         = var.vpc_config.subnet_ids
    security_group_ids = var.vpc_config.security_group_ids
  }

  environment {
    variables = var.environment_variables
  }

  layers = var.layer_arns
}

output "function_arn" {
  value = aws_lambda_function.function.arn
}

output "function_invoke_arn" {
  value = aws_lambda_function.function.invoke_arn
}

output "function_name" {
  value = aws_lambda_function.function.function_name
}
