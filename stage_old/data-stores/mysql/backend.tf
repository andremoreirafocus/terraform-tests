terraform {
  backend "s3" {
    # Replace this with your bucket name!
    bucket       = "terraform-up-and-running-state-andremoreirafocus"
    key          = "stage/data-stores/mysql/terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
    use_lockfile = true
  }
}