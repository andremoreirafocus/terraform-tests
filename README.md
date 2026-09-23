# Terraform AWS Tests

This project deploys a small MySQL-backed web application in AWS Ohio (us-east-2). An Application Load Balancer routes HTTP traffic to EC2 instances managed by an Auto Scaling group. The webserver resources are implemented in a reusable Terraform module.

```text
global/s3/                         S3 backend bucket and its configuration
stage/data-stores/mysql/           Stage root for the MySQL module and database state
modules/data-stores/mysql/          Reusable MySQL RDS module
modules/services/webserver-cluster Reusable webserver-cluster module
stage/services/webserver-cluster/  Stage root that calls the webserver module
```

Each root configuration has its own S3 state key:

```text
global/s3/terraform.tfstate
stage/data-stores/mysql/terraform.tfstate
stage/services/webserver-cluster/terraform.tfstate
```

The S3 backend uses versioning, AES256 encryption, public-access blocking, and S3 lockfiles. The backend bucket must exist before the other configurations can initialize.

Install Terraform, configure AWS credentials, and run commands from the project root. The database module must be applied before the webserver configuration because the webserver reads the database endpoint and port from the MySQL remote state. The MySQL module currently preserves the existing database settings; additional environment parameters are documented in MYSQL_MODULE_MIGRATION.md.

Initialize and verify the backend infrastructure:

```bash
terraform -chdir=global/s3 init
terraform -chdir=global/s3 plan
```

Create the MySQL database. Store credentials in stage/data-stores/mysql/.env using DB_USERNAME and DB_PASSWORD; the file is ignored by Git.

```bash
cd stage/data-stores/mysql
source ./vars.sh
terraform init
terraform plan
terraform apply
```

Deploy the stage webserver cluster:

```bash
cd ../../..
terraform -chdir=stage/services/webserver-cluster init
terraform -chdir=stage/services/webserver-cluster plan -var="server_port=80"
terraform -chdir=stage/services/webserver-cluster apply -var="server_port=80"
```

The stage root calls modules/data-stores/mysql for the database and modules/services/webserver-cluster for the application, then exposes the ALB DNS name and private IP addresses as root outputs. Open http://<alb_dns_name> after the Auto Scaling targets become healthy.

To remove the web application while retaining the backend bucket and database state:

```bash
terraform -chdir=stage/services/webserver-cluster destroy -var="server_port=80"
```

If Terraform reports a state lock, verify that no other operation is running. Only if the lock is stale, release it with the lock ID shown in the error:

```bash
terraform force-unlock <lock-id>
```

Commit .terraform.lock.hcl files to preserve provider versions. Local state files, .terraform directories, and database credentials are excluded by .gitignore.
