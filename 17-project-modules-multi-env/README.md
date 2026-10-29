# Project 17 — nginx Web App with Modules (dev + staging)

[← All labs](../README.md) · Full write-up with screenshots and break-&-fix: [terraform-modules-multi-env](https://github.com/Abhignadumpala/terraform-notes-kodekloud/blob/main/terraform-projects/terraform-modules-multi-env/README.md)

> **Goal:** build a full small stack — VPC, security group, IAM role, EC2 running nginx — from **reusable modules**, with state in **S3**, and deploy the same code to **dev** and **staging**.

**Before:** Labs [00](../00-setup/README.md), [12](../12-remote-state-s3-backend/README.md) done. Terraform **1.11+** (S3 native locking).

## Concept

**Module** = a folder of `.tf` files with **inputs** (`variables.tf`) and **outputs** (`outputs.tf`), called with a `module` block. Write once, use for every environment.

```
environments/dev/main.tf  ──►  module "nginx_web_app"  (modules/nginx-web-app)
                                   ├─► module "vpc"             VPC, public subnet, IGW, route table
                                   ├─► module "security_group"  HTTP 80 from anywhere, SSH 22 from my IP
                                   ├─► module "iam"             EC2 role + SSM policy + instance profile
                                   └─► module "ec2"             Amazon Linux + nginx (user_data)

vpc ──vpc_id──► security_group      vpc ──public_subnet_id──► ec2
security_group ──security_group_id──► ec2      iam ──instance_profile_name──► ec2
```

| Folder | Has | Run Terraform here? |
|---|---|---|
| `bootstrap/` | S3 state bucket (local state) | ✅ once, first |
| `environments/dev/`, `staging/` | backend `s3` + provider + **1 module call** + `terraform.tfvars` | ✅ |
| `modules/*` | the real resources | ❌ only called |

**Only `terraform.tfvars` and the backend `key` differ per environment:**

| | dev | staging |
|---|---|---|
| VPC CIDR | `10.0.0.0/16` | `10.1.0.0/16` |
| Subnet CIDR | `10.0.1.0/24` | `10.1.1.0/24` |
| Instance type | `t3.micro` | `t3.small` |
| State key in S3 | `dev/terraform.tfstate` | `staging/terraform.tfstate` |

## Files

```
code/
├── bootstrap/main.tf                 # S3 bucket + versioning + public access block, prevent_destroy
├── modules/
│   ├── vpc/                          # main.tf, variables.tf, outputs.tf
│   ├── security-group/
│   ├── iam/
│   ├── ec2/
│   └── nginx-web-app/                # calls the 4 modules and wires outputs → inputs
└── environments/
    ├── dev/                          # main.tf, variables.tf, terraform.tfvars, outputs.tf
    └── staging/
```

## Steps

### 1. Set your values

| File | Change |
|---|---|
| `bootstrap/main.tf`, `environments/dev/main.tf`, `environments/staging/main.tf` | `CHANGE-ME-tfstate-bucket` → your unique bucket name (same in all 3) |
| `environments/dev/terraform.tfvars`, `staging/terraform.tfvars` | `ssh_cidr` → your IP: `curl ifconfig.me`, add `/32` |

### 2. Bootstrap the state bucket (once)

```bash
cd 17-project-modules-multi-env/code/bootstrap
terraform init
terraform apply            # Plan: 3 to add → Apply complete! Resources: 3 added
```
Keep `bootstrap/terraform.tfstate` safe: it's the only record of the bucket.

### 3. Deploy dev

```bash
cd ../environments/dev
terraform init             # backend "s3" configured, 5 modules found
terraform fmt -recursive ../..
terraform validate
terraform plan             # Plan: 13 to add
terraform apply            # Apply complete! Resources: 13 added
```

My real results:
- `13 to add` = 5 VPC + 4 SG (1 SG + 3 rules) + 3 IAM + 1 EC2.
- Addresses are two modules deep: `module.nginx_web_app.module.ec2.aws_instance.nginx_server`.
- About 2 minutes later: `curl $(terraform output -raw nginx_url)` → **Hello from dev nginx**.

### 4. Deploy staging (same modules, different tfvars)

```bash
cd ../staging
terraform init
terraform apply
```
My result: **Hello from staging nginx**, and the dev page still said **Hello from dev nginx**. Separate state keys = staging never touched dev.

## Check

- EC2 console: `dev-nginx-server` (`t3.micro`) and the staging server (`t3.small`), 3/3 checks passed.
- Tags on every resource from the provider's `default_tags`: `Project`, `Environment`, `ManagedBy = terraform`.
- `aws s3 ls s3://<bucket> --recursive` → `dev/terraform.tfstate`, `staging/terraform.tfstate`.

## Clean up

```bash
cd environments/staging && terraform destroy
cd ../dev && terraform destroy
```
The state bucket has `prevent_destroy = true`. To delete it: set it to `false`, empty the bucket (all versions), then `terraform destroy` in `bootstrap/`.

## Interview one-liners

- A **module** = reusable folder with inputs and outputs; the **root** module is the folder you run Terraform in.
- Modules pass values **only through outputs → inputs**; a module can't read another module's resources directly.
- Same modules + different `tfvars` + different **state key** = separate environments from one codebase.
- `default_tags` in the provider tags every resource automatically.
- The **state bucket** lives in its own bootstrap config, protected with `prevent_destroy`, versioning and blocked public access.
