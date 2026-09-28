module "mysql" {
  source = "../modules/data-stores/mysql"

  db_username = var.db_username
  db_password = var.db_password
}

module "webserver_cluster" {
  source = "../modules/services/webserver-cluster"

  cluster_name = "webservers-prod"
  server_port  = var.server_port
  db_address   = module.mysql.db_address
  db_port      = module.mysql.db_port

  instance_type = "t2.micro"
  min_size      = 2
  max_size      = 2
}
