output "upper_names" {
  value = [for name in var.names : upper(name)]
}