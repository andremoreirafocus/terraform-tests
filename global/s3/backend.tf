terraform {
  backend "s3" {
    # Replace this with your bucket name!
    bucket         = "terraform-up-and-running-state-andremoreirafocus"
    key            = "global/s3/terraform.tfstate"
    region         = "us-east-2"
    encrypt        = true
    use_lockfile = true
    # Deprecated
    # Replace this with your DynamoDB table name!
    #dynamodb_table = "terraform-up-and-running-locks"
  }
}