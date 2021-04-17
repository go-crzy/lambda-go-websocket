variable "lambda_table" {
  type = string
  default = "WebsocketLambda"
}

variable "rx" {
  type = string
  default = "rx"
}

variable "rx_artifact" {
  type = string
  default = "ws-linux-amd64"
}

variable "http" {
  type = string
  default = "http"
}

variable "http_artifact" {
  type = string
  default = "http-linux-amd64"
}

