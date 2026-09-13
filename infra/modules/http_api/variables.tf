variable "api_name" {
  type = string
}

variable "stage_name" {
  type    = string
  default = "dev"
}

variable "routes" {
  description = <<-EOT
    Map de rotas: chave = "METHOD /path" (route key da HTTP API).
    Cada valor precisa de lambda_invoke_arn e lambda_function_name.
    authorizer_id é opcional (deixado nulo enquanto o tipo de authorizer é uma pendência).
  EOT
  type = map(object({
    lambda_invoke_arn    = string
    lambda_function_name = string
    authorizer_id        = optional(string)
  }))
}

variable "cors_allow_origins" {
  type    = list(string)
  default = ["*"]
}

variable "cors_allow_headers" {
  type    = list(string)
  default = ["content-type", "authorization"]
}

variable "cors_allow_methods" {
  type    = list(string)
  default = ["GET", "POST", "OPTIONS"]
}

variable "throttling_burst_limit" {
  type    = number
  default = 10
}

variable "throttling_rate_limit" {
  type    = number
  default = 20
}

variable "log_retention_in_days" {
  type    = number
  default = 14
}

variable "tags" {
  type    = map(string)
  default = {}
}
