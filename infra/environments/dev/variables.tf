variable "aws_region" {
  type    = string
  default = "us-east-2" # evidenciado pela base URL atual do frontend (penny)
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "project" {
  type    = string
  default = "gtw"
}

# Nomes das Lambdas já provisionadas em repositórios separados
# (~/dev/lambda/<repo>/infra). Este repositório só provisiona o API Gateway
# e referencia essas funções por nome via data source — não é dono do
# código nem do ciclo de vida delas.
variable "login_lambda_function_name" {
  type    = string
  default = "penny-python-login-lambda"
}

variable "register_card_lambda_function_name" {
  type    = string
  default = "penny-python-register-user-bank-card-function"
}

variable "get_user_cards_lambda_function_name" {
  type    = string
  default = "penny-python-get-user-bank-cards-function"
}

variable "register_expense_lambda_function_name" {
  type    = string
  default = "penny-python-register-expense-function"
}

variable "register_income_lambda_function_name" {
  type    = string
  default = "penny-python-register-income-function"
}

variable "get_user_transactions_lambda_function_name" {
  type    = string
  default = "penny-python-get-user-transactions-function"
}
