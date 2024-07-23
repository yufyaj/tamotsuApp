# 前提
# SESは手動で作成(ドメイン, メールアドレス)
# Route53のドメインも手動で設定(お名前.comと連携)
# lambdaにsdkレイヤーを事前に定義(aws-sdk-layer ver.1)

# ==========================================================
# 変数の設定
# ==========================================================
variable "aws_access_key_id" {}
variable "aws_secret_access_key" {}
variable "my_ip" {}
variable "my_domain" {
  default = "tamotsu-app.com"
}
variable "region" {
  default = "ap-northeast-1"
}
variable "availability_zone" {
  default = "ap-northeast-1a"
}
variable "vpc_cidr_block" {
  default = "10.0.0.0/16"
}
variable "public_subnet_cidr_block" {
  default = "10.0.1.0/24"
}
variable "send_mail_address" {
  default = "no-reply@tamotsu-app.com"
}

# AWSプロバイダーの設定
provider "aws" {
  region     = var.region
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
}

# VPCの設定
resource "aws_vpc" "tamotsu_vpc" {
  cidr_block = var.vpc_cidr_block
  tags       = {
    Name = "tamotsu-vpc"
  }
}

# パブリックサブネットの設定
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.tamotsu_vpc.id
  cidr_block        = var.public_subnet_cidr_block
  availability_zone = var.availability_zone
  tags = {
    Name = "tamotsu-public-subnet"
  }
}

# プライベートサブネットの設定
resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.tamotsu_vpc.id
  cidr_block = "10.0.2.0/24"  # パブリックサブネットとは異なるCIDRブロックを使用
  availability_zone = var.availability_zone
  tags = {
    Name = "tamotsu-private-subnet"
  }
}

# セキュリティグループの設定
resource "aws_security_group" "lambda_sg" {
  name        = "tamotsu-lambda-sg"
  description = "Security group for Lambda function"
  vpc_id      = aws_vpc.tamotsu_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip] # SSHアクセスを許可するIPアドレス
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# IAMロールの設定
resource "aws_iam_role" "lambda_role" {
  name = "tamotsu-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAMポリシーのアタッチ
resource "aws_iam_role_policy_attachment" "lambda_execute" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLambdaExecute"
}

resource "aws_iam_role_policy_attachment" "vpc_full_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
}

resource "aws_iam_role_policy_attachment" "s3_full_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "dynamodb_full_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_iam_role_policy_attachment" "ec2_full_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_role_policy_attachment" "ses_send_templated_email" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSESFullAccess"
}

resource "aws_iam_role_policy_attachment" "cognito_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonCognitoPowerUser"
}

# SES IDを取得
data "aws_ses_domain_identity" "tamotsu_domain" {
  domain = var.my_domain
}

# Cognito User Poolの作成
resource "aws_cognito_user_pool" "tamotsu_user_pool" {
  name = "tamotsu-user-pool"

  # メールアドレス検証を必須にする
  auto_verified_attributes = []

  # パスワードポリシー
  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  # メッセージング (SES)
  email_configuration {
    email_sending_account = "DEVELOPER"
    from_email_address    = "TAMOTSU <no-reply@tamotsu-app.com>"
    source_arn = data.aws_ses_domain_identity.tamotsu_domain.arn
  }

  admin_create_user_config {
    # ユーザーに自己サインアップを許可する。
    allow_admin_create_user_only = false
  }

  # カスタムフィールドの設定
  schema {
    name                = "verificationCode"
    attribute_data_type = "String"
    mutable             = true
    required            = false

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }
}

# Cognito User Pool Clientの作成
resource "aws_cognito_user_pool_client" "client" {
  name         = "tamotsu-user-pool-client"
  user_pool_id = aws_cognito_user_pool.tamotsu_user_pool.id

  # USER_PASSWORD_AUTH フローを有効にする
  explicit_auth_flows = ["ALLOW_USER_PASSWORD_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
}

# DynamoDBテーブルの作成
resource "aws_dynamodb_table" "tamotsu_user_table" {
  name           = "tamotsu-users" 
  billing_mode   = "PAY_PER_REQUEST"  # 従量課金モードに変更
  hash_key       = "id"                # ハッシュキーをidに変更

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "email"
    type = "S"
  }

  global_secondary_index {          # emailの重複を許さないためのGSIを追加
    name               = "email-index"
    hash_key           = "email"
    projection_type    = "ALL"
  }
}

# S3バケットの作成
resource "aws_s3_bucket" "tamotsu_images" {
  bucket = "tamotsu-images"
}

# 証明書の作成
resource "aws_acm_certificate" "tamotsu" {
  domain_name       = "api.${var.my_domain}"
  validation_method = "DNS"
}

# apiサブドメイン
resource "aws_api_gateway_domain_name" "tamotsu_app" {
  domain_name       = "api.${var.my_domain}"  # サブドメイン (例: api)
  regional_certificate_arn = aws_acm_certificate.tamotsu.arn
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# API Gatewayの作成
resource "aws_api_gateway_rest_api" "tamotsu_api" {
  name        = "tamotsu-api"
  description = "API Gateway for TAMOTSU"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# /user リソースの作成 (APIゲートウェイの子)
resource "aws_api_gateway_resource" "user_resource" {
  rest_api_id = aws_api_gateway_rest_api.tamotsu_api.id
  parent_id   = aws_api_gateway_rest_api.tamotsu_api.root_resource_id
  path_part   = "user"
  depends_on  = [aws_api_gateway_rest_api.tamotsu_api]
}

# /register リソースの作成 (apiリソースの子)
resource "aws_api_gateway_resource" "register" {
  rest_api_id = aws_api_gateway_rest_api.tamotsu_api.id
  parent_id   = aws_api_gateway_resource.user_resource.id  # 親リソースを/api/userに変更
  path_part   = "register"
}

# /login リソースの作成 (apiリソースの子)
resource "aws_api_gateway_resource" "login" {
  rest_api_id = aws_api_gateway_rest_api.tamotsu_api.id
  parent_id   = aws_api_gateway_resource.user_resource.id  # 親リソースを/api/userに変更
  path_part   = "login"
}

# /user/confirm リソースの作成
resource "aws_api_gateway_resource" "confirm" {
  rest_api_id = aws_api_gateway_rest_api.tamotsu_api.id
  parent_id   = aws_api_gateway_resource.user_resource.id
  path_part   = "confirm"
}

# /register リソースの POST メソッドの作成
resource "aws_api_gateway_method" "register_post" {
  rest_api_id   = aws_api_gateway_rest_api.tamotsu_api.id
  resource_id   = aws_api_gateway_resource.register.id
  http_method   = "POST"
  authorization = "NONE"
}

# /register リソースの POST メソッドの作成
resource "aws_api_gateway_method" "register_options" {
  rest_api_id   = aws_api_gateway_rest_api.tamotsu_api.id
  resource_id   = aws_api_gateway_resource.register.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# /login リソースの POST メソッドの作成
resource "aws_api_gateway_method" "login_post" {
  rest_api_id   = aws_api_gateway_rest_api.tamotsu_api.id
  resource_id   = aws_api_gateway_resource.login.id
  http_method   = "POST"
  authorization = "NONE"
}

# /user/confirm リソースの GET メソッドの作成
resource "aws_api_gateway_method" "confirm_get" {
  rest_api_id   = aws_api_gateway_rest_api.tamotsu_api.id
  resource_id   = aws_api_gateway_resource.confirm.id
  http_method   = "GET"
  authorization = "NONE"
}

# /register メソッドと Lambda 関数の連携
resource "aws_api_gateway_integration" "register_integration" {
  rest_api_id             = aws_api_gateway_rest_api.tamotsu_api.id
  resource_id             = aws_api_gateway_resource.register.id
  http_method             = aws_api_gateway_method.register_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.register_function.invoke_arn
}

# /register メソッドのreponse
resource "aws_api_gateway_integration_response" "post_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.tamotsu_api.id
  resource_id = aws_api_gateway_resource.register.id
  http_method = aws_api_gateway_method.register_post.http_method
  status_code = aws_api_gateway_method_response.register_post_reponse.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
}

# /register メソッドのreponse
resource "aws_api_gateway_method_response" "register_post_reponse" {
  rest_api_id = aws_api_gateway_rest_api.tamotsu_api.id
  resource_id = aws_api_gateway_resource.register.id
  http_method = aws_api_gateway_method.register_post.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

# /register メソッドと Lambda 関数の連携
resource "aws_api_gateway_integration" "register_options_integration" {
  rest_api_id             = aws_api_gateway_rest_api.tamotsu_api.id
  resource_id             = aws_api_gateway_resource.register.id
  http_method             = aws_api_gateway_method.register_options.http_method
  type                    = "MOCK"
  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }
}

# OPTIONSメソッドのレスポンス
resource "aws_api_gateway_method_response" "register_options_response" {
  rest_api_id = aws_api_gateway_rest_api.tamotsu_api.id
  resource_id = aws_api_gateway_resource.register.id
  http_method = aws_api_gateway_method.register_options.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

# OPTIONSメソッドの統合レスポンス
resource "aws_api_gateway_integration_response" "options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.tamotsu_api.id
  resource_id = aws_api_gateway_resource.register.id
  http_method = aws_api_gateway_method.register_options.http_method
  status_code = aws_api_gateway_method_response.register_options_response.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# /login メソッドと Lambda 関数の連携
resource "aws_api_gateway_integration" "login_integration" {
  rest_api_id             = aws_api_gateway_rest_api.tamotsu_api.id
  resource_id             = aws_api_gateway_resource.login.id
  http_method             = aws_api_gateway_method.login_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.login_function.invoke_arn
}

# /user/confirm メソッドと Lambda 関数の連携
resource "aws_api_gateway_integration" "confirm_integration" {
  rest_api_id = aws_api_gateway_rest_api.tamotsu_api.id
  resource_id = aws_api_gateway_resource.confirm.id
  http_method = aws_api_gateway_method.confirm_get.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.confirm_function.invoke_arn
}

# Lambdaレイヤーの取得
data "aws_lambda_layer_version" "aws_sdk_layer" {
  layer_name          = "aws-sdk-layer"
  version             = 1
}

# Lambda関数 (register)
resource "aws_lambda_function" "register_function" {
  function_name = "tamotsu-register-function"
  filename      = "../api/user/register/register.zip"
  handler       = "register.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.lambda_role.arn
  timeout       = 15
  vpc_config {
    subnet_ids         = [aws_subnet.private_subnet.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
  environment {
    variables = {
      FROM_EMAIL_ADDRESS          = var.send_mail_address
      COGNITO_USER_POOL_CLIENT_ID = aws_cognito_user_pool_client.client.id
    }
  }
  layers = [data.aws_lambda_layer_version.aws_sdk_layer.arn]
}

# Lambda関数 (login)
resource "aws_lambda_function" "login_function" {
  function_name = "tamotsu-login-function"
  filename      = "../api/user/login/login.zip"       # ログイン用 Lambda 関数のコード (login.js) を含む zip ファイル
  handler       = "login.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.lambda_role.arn
  timeout       = 15
  vpc_config {
    subnet_ids         = [aws_subnet.private_subnet.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
  environment {
    variables = {
      COGNITO_USER_POOL_CLIENT_ID = aws_cognito_user_pool_client.client.id
    }
  }
  layers = [data.aws_lambda_layer_version.aws_sdk_layer.arn]
}

# Lambda関数 (confirm)
resource "aws_lambda_function" "confirm_function" {
  function_name = "tamotsu-confirm-function"
  filename      = "../api/user/confirm/confirm.zip"
  handler       = "confirm.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.lambda_role.arn
  timeout       = 15

  vpc_config {
    subnet_ids         = [aws_subnet.private_subnet.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  environment {
    variables = {
      COGNITO_USER_POOL_ID = aws_cognito_user_pool.tamotsu_user_pool.id
    }
  }

  layers = [data.aws_lambda_layer_version.aws_sdk_layer.arn]
}

# Lambda 関数に API Gateway からのアクセスを許可 (register)
resource "aws_lambda_permission" "apigw_register_lambda" {
  depends_on = [
    aws_api_gateway_deployment.tamotsu_deployment,
  ]
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.register_function.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.tamotsu_api.execution_arn}/*/${aws_api_gateway_method.register_post.http_method}${aws_api_gateway_resource.register.path}"
}

# Lambda 関数に API Gateway からのアクセスを許可 (login)
resource "aws_lambda_permission" "apigw_login_lambda" {
  depends_on = [
    aws_api_gateway_deployment.tamotsu_deployment,
  ]
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.login_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.tamotsu_api.execution_arn}/*/${aws_api_gateway_method.login_post.http_method}${aws_api_gateway_resource.login.path}"
}

# Lambda 関数に API Gateway からのアクセスを許可 (confirm)
resource "aws_lambda_permission" "apigw_confirm_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.confirm_function.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.tamotsu_api.execution_arn}/*/${aws_api_gateway_method.confirm_get.http_method}${aws_api_gateway_resource.confirm.path}"
}

# API Gateway のデプロイ
resource "aws_api_gateway_deployment" "tamotsu_deployment" {
  depends_on = [
    aws_api_gateway_integration.register_integration,
    aws_api_gateway_integration.login_integration,
    aws_api_gateway_integration.confirm_integration,
  ]

  rest_api_id = aws_api_gateway_rest_api.tamotsu_api.id
  stage_name  = "dev"
}

# API Gatewayのマッピングを作成
resource "aws_api_gateway_base_path_mapping" "tamotsu_app" {
  api_id      = aws_api_gateway_rest_api.tamotsu_api.id
  stage_name  = "dev"
  domain_name = aws_api_gateway_domain_name.tamotsu_app.domain_name
}

# SESの設定
resource "aws_ses_configuration_set" "tamotsu_config" {
  name = "tamotsu-config-set"
}

# CognitoへのVPCエンドポイントはサポートされていないらしい？
# NATゲートウェイの作成
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.tamotsu_vpc.id

  tags = {
    Name = "tamotsu-igw"
  }
}

# ルートテーブルの作成
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.tamotsu_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "tamotsu-public-route-table"
  }
}

# パブリックサブネットにルートテーブルを関連付ける
resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id
  tags = {
    Name = "tamotsu-nat-gateway"
  }
}

# ルートテーブルの修正
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.tamotsu_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name = "tamotsu-private-route-table"
  }
}

resource "aws_route_table_association" "private_route_assoc" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}