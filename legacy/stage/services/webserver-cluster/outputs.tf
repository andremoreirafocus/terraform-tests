output "alb_dns_name" {
  value = module.webserver_cluster.alb_dns_name
}

output "ec2_instance_private_ips" {
  value = module.webserver_cluster.ec2_instance_private_ips
}
