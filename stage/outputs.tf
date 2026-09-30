# output "alb_dns_name" {
#   value = module.webserver_cluster.alb_dns_name
# }

# output "ec2_instance_private_ips" {
#   value = module.webserver_cluster.ec2_instance_private_ips
# }

# output "db_address" {
#   value = module.mysql.db_address
# }

# output "db_port" {
#   value = module.mysql.db_port
# }

# output "asg_name" {
#   value = module.webserver_cluster.asg_name
# }

output "all_users" {
  value = module.users[*]
}


output "neo_cloudwatch_policy_arn" {
  value = (
    var.give_neo_cloudwatch_full_access
    ? aws_iam_user_policy_attachment.neo_cloudwatch_full_access[0].policy_arn
    : aws_iam_user_policy_attachment.neo_cloudwatch_read_only[0].policy_arn
  )
}