variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
}

variable "db_address" {
  description = "The database endpoint"
  type        = string
}

variable "db_port" {
  description = "The database port"
  type        = number
}
