
module "mysql" {
  source = "github.com/andremoreirafocus/terraform-modules.git//modules/data-stores/mysql?ref=v0.0.1"
  db_username = var.db_username
  db_password = var.db_password
}

module "webserver_cluster" {
  source = "github.com/andremoreirafocus/terraform-modules.git//modules/services/webserver-cluster?ref=v0.0.6"

  cluster_name = "webservers-stage"
  server_port  = var.server_port
  db_address   = module.mysql.db_address
  db_port      = module.mysql.db_port

  instance_type = "t2.micro"
  min_size      = 2
  max_size      = 2
  enable_autoscaling = false
}

module "users" {
  source = "github.com/andremoreirafocus/terraform-modules.git//modules/landing-zone/iam-user?ref=v0.0.6"
  user_names = var.user_names

  # source = "github.com/andremoreirafocus/terraform-modules.git//modules/landing-zone/iam-user?ref=v0.0.2"

  # count     = length(var.user_names)
  # user_name = var.user_names[count.index]
  # or
  # for_each  = toset(var.user_names)
  # user_name = each.value
}

resource "aws_iam_policy" "cloudwatch_read_only" {
  name   = "cloudwatch-read-only"
  policy = data.aws_iam_policy_document.cloudwatch_read_only.json
}

data "aws_iam_policy_document" "cloudwatch_read_only" {
  statement {
    effect    = "Allow"
    actions   = [
      "cloudwatch:Describe*",
      "cloudwatch:Get*",
      "cloudwatch:List*"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "cloudwatch_full_access" {
  name   = "cloudwatch-full-access"
  policy = data.aws_iam_policy_document.cloudwatch_full_access.json
}

data "aws_iam_policy_document" "cloudwatch_full_access" {
  statement {
    effect    = "Allow"
    actions   = ["cloudwatch:*"]
    resources = ["*"]
  }
}