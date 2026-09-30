output "alb_dns_name" {
  value = module.webserver_cluster.alb_dns_name
}

output "ec2_instance_private_ips" {
  value = module.webserver_cluster.ec2_instance_private_ips
}

output "db_address" {
  value = module.mysql.db_address
}

output "db_port" {
  value = module.mysql.db_port
}

output "all_users" {
  value = module.users[*]
}

output "asg_name" {
  value = module.webserver_cluster.asg_name
}