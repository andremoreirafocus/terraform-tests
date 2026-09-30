module "mysql" {
  # source = "../modules/data-stores/mysql"
  source      = "github.com/andremoreirafocus/terraform-modules.git//modules/data-stores/mysql?ref=v0.0.1"
  db_username = var.db_username
  db_password = var.db_password
}

module "webserver_cluster" {
  # source = "../modules/services/webserver-cluster"
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

# resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
#   scheduled_action_name = "scale-out-during-business-hours"
#   min_size              = 2
#   max_size              = 5
#   desired_capacity      = 5
#   recurrence            = "0 9 * * *"

#   autoscaling_group_name = module.webserver_cluster.asg_name
# }

# resource "aws_autoscaling_schedule" "scale_in_at_night" {
#   scheduled_action_name = "scale-in-at-night"
#   min_size              = 2
#   max_size              = 3
#   desired_capacity      = 2
#   recurrence            = "0 18 * * *"

#   autoscaling_group_name = module.webserver_cluster.asg_name
# }
