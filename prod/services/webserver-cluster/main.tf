data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    bucket = "terraform-up-and-running-state-andremoreirafocus"
    key    = "prod/data-stores/mysql/terraform.tfstate"
    region = "us-east-2"
  }
}

module "webserver_cluster" {
  source = "../../../modules/services/webserver-cluster"

  server_port = var.server_port
  db_address  = data.terraform_remote_state.db.outputs.address
  db_port     = data.terraform_remote_state.db.outputs.port
}
