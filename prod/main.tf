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

  instance_type = "t3.micro"
  min_size      = 2
  max_size      = 2
}

resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
  scheduled_action_name = "scale-out-during-business-hours"
  min_size              = 2
  max_size              = 5
  desired_capacity      = 5
  recurrence            = "15 20 * * *"

  autoscaling_group_name = module.webserver_cluster.asg_name
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
  scheduled_action_name = "scale-in-at-night"
  min_size              = 2
  max_size              = 3
  desired_capacity      = 2
  recurrence            = "5 20 * * *"

  autoscaling_group_name = module.webserver_cluster.asg_name
}
