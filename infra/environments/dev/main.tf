locals {
  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  name_prefix = "${var.project}-${var.environment}"
}

# As Lambdas vivem em repositórios/diretórios próprios (~/dev/lambda/<repo>),
# cada uma com seu próprio Terraform (function, IAM role, VPC). Este
# repositório não as provisiona: apenas referencia as funções já existentes
# por nome, e cuida do API Gateway (rotas, integrações, permissões, stage).

data "aws_lambda_function" "login" {
  function_name = var.login_lambda_function_name
}

data "aws_lambda_function" "register_card" {
  function_name = var.register_card_lambda_function_name
}

data "aws_lambda_function" "get_user_cards" {
  function_name = var.get_user_cards_lambda_function_name
}

data "aws_lambda_function" "register_expense" {
  function_name = var.register_expense_lambda_function_name
}

data "aws_lambda_function" "register_income" {
  function_name = var.register_income_lambda_function_name
}

data "aws_lambda_function" "get_user_transactions" {
  function_name = var.get_user_transactions_lambda_function_name
}

module "http_api" {
  source     = "../../modules/http_api"
  api_name   = "${local.name_prefix}-api"
  stage_name = var.environment
  tags       = local.tags

  # authorizer_id fica nulo em todas as rotas: o tipo de authorizer (Lambda
  # authorizer simples vs JWT/Cognito) é pendência (seção 11/14 do plano).
  routes = {
    "POST /auth" = {
      lambda_invoke_arn    = data.aws_lambda_function.login.invoke_arn
      lambda_function_name = data.aws_lambda_function.login.function_name
    }
    "POST /cards" = {
      lambda_invoke_arn    = data.aws_lambda_function.register_card.invoke_arn
      lambda_function_name = data.aws_lambda_function.register_card.function_name
    }
    "GET /cards/{idUser}" = {
      lambda_invoke_arn    = data.aws_lambda_function.get_user_cards.invoke_arn
      lambda_function_name = data.aws_lambda_function.get_user_cards.function_name
    }
    "POST /expenses" = {
      lambda_invoke_arn    = data.aws_lambda_function.register_expense.invoke_arn
      lambda_function_name = data.aws_lambda_function.register_expense.function_name
    }
    "POST /incomes" = {
      lambda_invoke_arn    = data.aws_lambda_function.register_income.invoke_arn
      lambda_function_name = data.aws_lambda_function.register_income.function_name
    }
    "GET /transactions" = {
      lambda_invoke_arn    = data.aws_lambda_function.get_user_transactions.invoke_arn
      lambda_function_name = data.aws_lambda_function.get_user_transactions.function_name
    }
  }
}
