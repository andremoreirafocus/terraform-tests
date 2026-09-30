module "mysql" {
  source      = "github.com/andremoreirafocus/terraform-modules.git//modules/data-stores/mysql?ref=v0.0.1"
  db_username = var.db_username
  db_password = var.db_password
}

module "webserver_cluster" {
  source = "github.com/andremoreirafocus/terraform-modules.git//modules/services/webserver-cluster?ref=v0.0.6"

  cluster_name = "webservers-prod"
  server_port  = var.server_port
  db_address   = module.mysql.db_address
  db_port      = module.mysql.db_port

  instance_type = "t3.micro"
  min_size      = 2
  max_size      = 2
  enable_autoscaling = true


  custom_tags = {
    Owner     = "team-focus"
    ManagedBy = "andrem"
  }  
}
