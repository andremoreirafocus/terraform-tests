
module "mysql" {
  # source = "../modules/data-stores/mysql"
  source = "github.com/andremoreirafocus/terraform-modules.git//modules/data-stores/mysql?ref=v0.0.1"
  db_username = var.db_username
  db_password = var.db_password
}

module "webserver_cluster" {
  # source = "../modules/services/webserver-cluster"
  source = "github.com/andremoreirafocus/terraform-modules.git//modules/services/webserver-cluster?ref=v0.0.1"

  cluster_name = "webservers-stage"
  server_port  = var.server_port
  db_address   = module.mysql.db_address
  db_port      = module.mysql.db_port

  instance_type = "t2.micro"
  min_size      = 2
  max_size      = 2
}

module "users" {
  source = "github.com/andremoreirafocus/terraform-modules.git//modules/landing-zone/iam-user?ref=v0.0.3"

  count     = length(var.user_names)
  user_name = var.user_names[count.index]
}
