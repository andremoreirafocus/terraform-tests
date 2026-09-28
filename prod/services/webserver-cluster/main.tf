module "webserver_cluster" {
  source = "../../../modules/services/webserver-cluster"

  cluster_name           = "webservers-prod"
  server_port            = var.server_port
  db_remote_state_bucket = "terraform-up-and-running-state-andremoreirafocus"
  db_remote_state_key    = "prod/data-stores/mysql/terraform.tfstate"
}
