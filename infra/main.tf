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

# lambdaに適用するIAMの定義
locals {
  lambda_iam = {
    lambda_execute           = {
      policy_arn = "arn:aws:iam::aws:policy/AWSLambdaExecute"
    }
    vpc_full_access          = {
      policy_arn = "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
    }
    s3_full_access           = {
      policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
    }
    dynamodb_full_access     = {
      policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
    }
    ec2_full_access          = {
      policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
    }
    ses_send_templated_email = {
      policy_arn = "arn:aws:iam::aws:policy/AmazonSESFullAccess"
    }
    cognito_access           = {
      policy_arn = "arn:aws:iam::aws:policy/AmazonCognitoPowerUser"
    }
  }
}

# IAMポリシーのアタッチ
resource "aws_iam_role_policy_attachment" "lambda_execute" {
  for_each = local.lambda_iam

  role       = aws_iam_role.lambda_role.name
  policy_arn = each.value.policy_arn
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

# Route 53のホストゾーンを取得（既存のホストゾーンを使用する場合）
data "aws_route53_zone" "tamotsu_app" {
  name = "tamotsu-app.com"
}

# Route 53にAレコードを追加
resource "aws_route53_record" "record_tamotsu_app" {
  zone_id = data.aws_route53_zone.tamotsu_app.zone_id
  name    = "api.tamotsu-app.com"
  type    = "A"

  alias {
    name                   = aws_api_gateway_domain_name.tamotsu_app.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.tamotsu_app.regional_zone_id
    evaluate_target_health = true
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


# lambdaの定義
locals {
  lambda_functions = {
    register = {
      filename = "../api/user/register/register.zip"
      handler  = "register.handler"
      env_vars = {
        FROM_EMAIL_ADDRESS          = var.send_mail_address
        COGNITO_USER_POOL_CLIENT_ID = aws_cognito_user_pool_client.client.id
      }
      http_method = "POST"
      parent_id   = aws_api_gateway_resource.user_resource.id  # 親リソースを設定
    }
    login = {
      filename = "../api/user/login/login.zip"
      handler  = "login.handler"
      env_vars = {
        COGNITO_USER_POOL_CLIENT_ID = aws_cognito_user_pool_client.client.id
      }
      http_method = "POST"
      parent_id   = aws_api_gateway_resource.user_resource.id  # 親リソースを設定
    }
    confirm = {
      filename = "../api/user/confirm/confirm.zip"
      handler  = "confirm.handler"
      env_vars = {
        COGNITO_USER_POOL_ID = aws_cognito_user_pool.tamotsu_user_pool.id
      }
      http_method = "GET"
      parent_id   = aws_api_gateway_resource.user_resource.id  # 親リソースを設定
    }
  }
}

# 関数のリソースの作成 (userリソースの子)
resource "aws_api_gateway_resource" "gw_resources" {
  for_each = local.lambda_functions

  rest_api_id = aws_api_gateway_rest_api.tamotsu_api.id
  parent_id   = each.value.parent_id
  path_part   = each.key
}

# 関数用メソッド[OPTIONS]の作成
resource "aws_api_gateway_method" "gw_options" {
  for_each = local.lambda_functions

  rest_api_id   = aws_api_gateway_rest_api.tamotsu_api.id
  resource_id   = aws_api_gateway_resource.gw_resources[each.key].id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# 関数用メソッドの作成
resource "aws_api_gateway_method" "gw_methods" {
  for_each = local.lambda_functions

  rest_api_id   = aws_api_gateway_rest_api.tamotsu_api.id
  resource_id   = aws_api_gateway_resource.gw_resources[each.key].id
  http_method   = each.value.http_method
  authorization = "NONE"
}

# 関数用メソッド[OPTIONS]とlambda関数を統合
resource "aws_api_gateway_integration" "gw_options_integrations" {
  for_each = local.lambda_functions

  rest_api_id             = aws_api_gateway_rest_api.tamotsu_api.id
  resource_id             = aws_api_gateway_resource.gw_resources[each.key].id
  http_method             = aws_api_gateway_method.gw_options[each.key].http_method
  type                    = "MOCK"
  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }
}

# 関数用メソッドとlambda関数を統合
resource "aws_api_gateway_integration" "gw_method_integrations" {
  for_each = local.lambda_functions

  rest_api_id = aws_api_gateway_rest_api.tamotsu_api.id
  resource_id = aws_api_gateway_resource.gw_resources[each.key].id
  http_method = each.value.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.lambda_functions[each.key].function_invoke_arn
}

# lambda関数からapi gwへのレスポンス[OPTIONS]
resource "aws_api_gateway_integration_response" "gw_options_integration_responses" {
  for_each = local.lambda_functions

  rest_api_id = aws_api_gateway_rest_api.tamotsu_api.id
  resource_id = aws_api_gateway_resource.gw_resources[each.key].id
  http_method = aws_api_gateway_method.gw_options[each.key].http_method
  status_code = aws_api_gateway_method_response.gw_options_responses[each.key].status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [aws_api_gateway_integration.gw_options_integrations]
}

# lambda関数からapi gwへのレスポンス
resource "aws_api_gateway_integration_response" "gw_method_integration_responses" {
  for_each = local.lambda_functions

  rest_api_id = aws_api_gateway_rest_api.tamotsu_api.id
  resource_id = aws_api_gateway_resource.gw_resources[each.key].id
  http_method = aws_api_gateway_method.gw_methods[each.key].http_method
  status_code = aws_api_gateway_method_response.gw_method_reponses[each.key].status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
}

# api gwからのreponse[OPTIONS]
resource "aws_api_gateway_method_response" "gw_options_responses" {
  for_each = local.lambda_functions

  rest_api_id = aws_api_gateway_rest_api.tamotsu_api.id
  resource_id = aws_api_gateway_resource.gw_resources[each.key].id
  http_method = aws_api_gateway_method.gw_options[each.key].http_method
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


# api gwからのreponse
resource "aws_api_gateway_method_response" "gw_method_reponses" {
  for_each = local.lambda_functions

  rest_api_id = aws_api_gateway_rest_api.tamotsu_api.id
  resource_id = aws_api_gateway_resource.gw_resources[each.key].id
  http_method = aws_api_gateway_method.gw_methods[each.key].http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

# Lambdaレイヤーの取得
data "aws_lambda_layer_version" "aws_sdk_layer" {
  layer_name          = "aws-sdk-layer"
  version             = 1
}

# Lambda関数実装
module "lambda_functions" {
  source   = "./modules/lambda"
  for_each = local.lambda_functions

  function_name = "tamotsu-${each.key}-function"
  filename      = each.value.filename
  handler       = each.value.handler
  runtime       = "nodejs20.x"
  role_arn      = aws_iam_role.lambda_role.arn

  vpc_config = {
    subnet_ids         = [aws_subnet.private_subnet.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  environment_variables = each.value.env_vars
  layer_arns            = [data.aws_lambda_layer_version.aws_sdk_layer.arn]
}

# Lambda 関数に API Gateway からのアクセスを許可
resource "aws_lambda_permission" "api_gw_lambda_permissions" {
  for_each = local.lambda_functions

  depends_on = [
    aws_api_gateway_deployment.tamotsu_deployment,
  ]
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_functions[each.key].function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.tamotsu_api.execution_arn}/*/${each.value.http_method}${aws_api_gateway_resource.gw_resources[each.key].path}"
}

# API Gateway のデプロイ
resource "aws_api_gateway_deployment" "tamotsu_deployment" {
  depends_on = [
    aws_api_gateway_integration.gw_method_integrations,
    aws_api_gateway_integration.gw_options_integrations
  ]

  rest_api_id = aws_api_gateway_rest_api.tamotsu_api.id
  stage_name  = "dev"

  # 変更がある場合のみ再デプロイするためのトリガー
  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_integration.gw_method_integrations))
  }
}

# API Gatewayのマッピングを作成
resource "aws_api_gateway_base_path_mapping" "tamotsu_app" {
  api_id      = aws_api_gateway_rest_api.tamotsu_api.id
  stage_name  = aws_api_gateway_deployment.tamotsu_deployment.stage_name
  domain_name = aws_api_gateway_domain_name.tamotsu_app.domain_name

  depends_on = [aws_api_gateway_deployment.tamotsu_deployment]
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