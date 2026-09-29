# Terraform AWS Tests

This repository contains the production and stage root configurations for a MySQL-backed web application in AWS Ohio (`us-east-2`). An Application Load Balancer routes HTTP traffic to EC2 instances in an Auto Scaling group.

The reusable MySQL and webserver-cluster modules are maintained in a separate, versioned modules repository. They are intentionally not included in this repository.

```text
global/s3/  Creates the S3 backend bucket
prod/       Production root configuration
stage/      Stage root configuration
legacy/     Historical local module and root configurations; do not use for deployment
```

## External modules

The current `prod/main.tf` and `stage/main.tf` still refer to the removed local paths (`../modules/...`). They are not runnable until both module `source` attributes are changed to the external modules repository. Do not run `terraform init`, `plan`, or `apply` in either environment until that change is complete.

Pin each module to an immutable release tag or commit. For a Git-hosted repository, the module calls should follow this pattern (replace every placeholder with the actual repository, subdirectory, and release):

```hcl
module "mysql" {
  source = "git::https://github.com/<organization>/<terraform-modules-repository>.git//<mysql-module-path>?ref=v<version>"

  # ...
}

module "webserver_cluster" {
  source = "git::https://github.com/<organization>/<terraform-modules-repository>.git//<webserver-cluster-module-path>?ref=v<version>"

  # ...
}
```

Do not pin to a mutable branch such as `main`. If the modules are published through a Terraform module registry instead, use that registry source address and its `version` argument.

### Required module interface

Before selecting a release, confirm it is compatible with these root configurations:

| Module | Required inputs | Required outputs |
| --- | --- | --- |
| MySQL | `db_username`, `db_password` | `db_address`, `db_port` |
| Webserver cluster | `cluster_name`, `server_port`, `db_address`, `db_port`, `instance_type`, `min_size`, `max_size` | `alb_dns_name`, `ec2_instance_private_ips`, `asg_name` |

`prod` uses `asg_name` for its Auto Scaling schedules. Both roots pass MySQL outputs directly into the webserver module, so Terraform creates the database before it creates the launch template. No `terraform_remote_state` data source is used.

Changing only a module source does not require a state migration if the module names and all resource addresses within the selected external module remain the same. Review the first plan carefully; resource replacements or deletes indicate an incompatible module release or changed resource addresses.

## Remote state

Each environment has one combined S3 state object:

```text
terraform-up-and-running-state-andremoreirafocus/prod/systems/web-app/terraform.tfstate
terraform-up-and-running-state-andremoreirafocus/stage/systems/web-app/terraform.tfstate
```

The S3 backend uses server-side encryption and S3 lock files (`use_lockfile = true`). The backend bucket configuration in `global/s3` enables versioning and blocks public access.

If MySQL or webserver resources were previously created from separate state files, do **not** apply a combined root until their state has been migrated or imported into the appropriate combined state. Otherwise Terraform can propose duplicate resources.

When intentionally changing a backend target, use `terraform init -migrate-state` to migrate state. Use `terraform init -reconfigure` only when refreshing Terraform's locally cached backend settings without moving state.

## Prerequisites

- Terraform installed
- AWS credentials with access to the backend bucket and permission to create the configured AWS resources
- The backend bucket already created by `global/s3`
- External module sources set to compatible, pinned releases

Create `<environment>/.env` locally; it is ignored by Git:

```dotenv
DB_USERNAME=your_database_username
DB_PASSWORD=your_database_password
```

`prod/vars.sh` and `stage/vars.sh` export these values as Terraform input variables without printing them.

## Deploy an environment

After updating the module sources, replace `<environment>` with `prod` or `stage`:

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

## State locks

Terraform creates an S3 lock object while planning or applying. An `Error acquiring the state lock` response with S3 status `412 PreconditionFailed` and a `Lock Info` block means Terraform found an existing lock object. The `Operation`, `Who`, and `Created` fields identify the operation that owns it.

You do not need the AWS CLI to confirm this: Terraform's error already reports the lock and its ID. First confirm that no other Terraform plan, apply, CI job, or terminal is operating on the same state. If the recorded operation has stopped, release only the lock ID shown in the error:

```bash
terraform force-unlock <lock-id>
```

Terraform prompts for confirmation. After it succeeds, retry `terraform plan`. Do not use `-lock=false` for normal operations, manually delete the S3 lock object, or force-unlock a lock held by an active operation.

## Repository hygiene

Commit `.terraform.lock.hcl` files so all users select the same provider versions. Do not commit `.env`, `.terraform/`, or `*.tfstate` files.
