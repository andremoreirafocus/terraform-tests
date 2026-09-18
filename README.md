# Terraform AWS Tests

A learning project that deploys a "Hello, World" web server cluster on AWS in Ohio (`us-east-2`). An Application Load Balancer routes HTTP traffic to EC2 instances managed by an Auto Scaling group with a minimum of two and maximum of three instances.

```text
global/s3/                         S3 infrastructure for remote Terraform state
stage/services/webserver-cluster/  Launch template, Auto Scaling group, ALB, and security groups
```

Each directory is an independent Terraform configuration, split into resource, provider, backend, output, and (where needed) variable files. Both configurations use the same S3 bucket with separate state keys and S3 lockfiles. The bucket has versioning, encryption, public access blocking, and deletion protection through Terraform.

Install Terraform and configure AWS credentials before running the commands below from the project root. The S3 backend bucket must already exist before initialization; it was bootstrapped separately for this project.

Review the state infrastructure:

```bash
terraform -chdir=global/s3 init
terraform -chdir=global/s3 plan
```

Deploy the webserver cluster:

```bash
terraform -chdir=stage/services/webserver-cluster init
terraform -chdir=stage/services/webserver-cluster plan -var="server_port=80"
terraform -chdir=stage/services/webserver-cluster apply -var="server_port=80"
```

The cluster outputs the ALB DNS name and instance private IP addresses. Open `http://<alb_dns_name>` to access the application after its targets become healthy.

To remove the application while retaining the state bucket:

```bash
terraform -chdir=stage/services/webserver-cluster destroy -var="server_port=80"
```

Commit `.terraform.lock.hcl` files to preserve provider versions. Local state files and `.terraform` directories are excluded by `.gitignore`.
