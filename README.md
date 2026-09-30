# Terraform AWS Tests

This repository contains Terraform exercises and AWS root configurations for the `us-east-2` (Ohio) region. The deployable environments create a MySQL-backed web application: an Application Load Balancer routes HTTP traffic to EC2 instances in an Auto Scaling group.

The reusable infrastructure modules are maintained in the separate [`terraform-modules`](https://github.com/andremoreirafocus/terraform-modules) repository. The local `legacy/` directory is retained only as historical reference.

```text
dev/        Local Terraform expression/output experiments; no remote backend
global/s3/  Creates and configures the S3 remote-state bucket
prod/       Production web application root configuration
stage/      Stage web application root configuration, IAM users, and IAM policies
legacy/     Historical local modules and split roots; do not use for deployment
```

## External modules

The active roots reference the external MySQL and webserver-cluster modules; stage also references the IAM-user module. The module blocks in [prod/main.tf](prod/main.tf) and [stage/main.tf](stage/main.tf) are the source of truth for their exact source addresses and pinned releases.

Keep module references pinned. Release tags should be protected against mutation; use a commit SHA when that guarantee is unavailable.

### Module interface used here

| Module | Required inputs | Outputs used by this repository |
| --- | --- | --- |
| MySQL | `db_username`, `db_password` | `db_address`, `db_port` |
| Webserver cluster | `cluster_name`, `server_port`, `db_address`, `db_port`, `instance_type`, `min_size`, `max_size`, `enable_autoscaling` | `alb_dns_name`, `ec2_instance_private_ips`, `asg_name` |
| IAM users (stage only) | `user_names` | `all_users` |

`custom_tags` is optional for the webserver module and is configured in `prod`. Both application roots pass the MySQL outputs directly into the webserver module, so Terraform creates the database before the launch template. They do not use `terraform_remote_state`.

Production enables the webserver module's scheduled Auto Scaling behavior; stage disables it. Both roots expose the Auto Scaling group name as an output. Stage also creates IAM users from `user_names` and creates unattached CloudWatch read-only and full-access IAM policies.

## Remote state

`prod` and `stage` each use one combined S3 state object:

```text
terraform-up-and-running-state-andremoreirafocus/prod/systems/web-app/terraform.tfstate
terraform-up-and-running-state-andremoreirafocus/stage/systems/web-app/terraform.tfstate
```

`global/s3` stores its own state at `global/s3/terraform.tfstate`. The backend bucket has versioning, default SSE-S3 encryption, public-access blocking, and S3 lock files (`use_lockfile = true`). `dev` has no backend configuration, so its local state remains ignored by Git.

If MySQL or webserver resources were previously created from separate state files, do **not** apply a combined root until their state has been migrated or imported into the appropriate combined state. Otherwise Terraform can propose duplicate resources.

When intentionally changing a backend target, use `terraform init -migrate-state` to migrate state. Use `terraform init -reconfigure` only to refresh Terraform's locally cached backend settings without moving state.

### Bootstrap the backend bucket

The `global/s3` configuration refers to the bucket it creates, so the first bootstrap must start with the backend disabled:

```bash
cd global/s3
terraform init -backend=false
terraform apply
terraform init -migrate-state
```

If the bucket and its state already exist, initialize `global/s3` normally with `terraform init`.

## Prerequisites

- Terraform installed
- AWS credentials with access to the backend bucket and permission to create the configured AWS resources
- Network access to the external module repository
- The backend bucket bootstrapped through `global/s3`

Create `prod/.env` and `stage/.env` locally; they are ignored by Git:

```dotenv
DB_USERNAME=your_database_username
DB_PASSWORD=your_database_password
```

`prod/vars.sh` and `stage/vars.sh` export these values as sensitive Terraform input variables without printing them.

## Deploy an environment

Replace `<environment>` with `prod` or `stage`:

```bash
cd <environment>
source ./vars.sh
terraform fmt -check
terraform init
terraform plan -var="server_port=80"
terraform apply -var="server_port=80"
```

Always review the plan before applying. After a successful apply, retrieve the load balancer address with:

```bash
terraform output -raw alb_dns_name
```

The stage user names default to values declared in [stage/variables.tf](stage/variables.tf); override them with `-var='user_names=["name1","name2"]'` when needed.

## State locks

Terraform creates an S3 lock object while planning or applying. An `Error acquiring the state lock` response with S3 status `412 PreconditionFailed` and a `Lock Info` block means Terraform found an existing lock object. The `Operation`, `Who`, and `Created` fields identify the operation that owns it.

First confirm that no other Terraform plan, apply, CI job, or terminal is operating on the same state. If the recorded operation has stopped, release only the lock ID shown in the error:

```bash
terraform force-unlock <lock-id>
```

Terraform prompts for confirmation. After it succeeds, retry `terraform plan`. Do not use `-lock=false` for normal operations, manually delete the S3 lock object, or force-unlock a lock held by an active operation.

## Repository hygiene

Commit `.terraform.lock.hcl` files so all users select the same provider versions. Do not commit `.env`, `.terraform/`, or local `*.tfstate` files. Run `terraform fmt -recursive` before committing Terraform changes.
