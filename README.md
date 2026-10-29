# Terraform AWS Labs — Step by Step

Hands-on labs that create **real AWS resources with Terraform**, from a first EC2 server up to a multi-environment project built with modules. Each lab has the code, the commands in order, what you should see, and how to clean up.

> 📘 Detailed theory for every topic: [terraform-notes-kodekloud](https://github.com/Abhignadumpala/terraform-notes-kodekloud) (my KodeKloud Terraform course notes). This repo is **labs only**.

---

## Table of Contents

1. [What is Terraform?](#what-is-terraform)
2. [Why Terraform?](#why-terraform)
3. [Theory in short](#theory-in-short)
4. [How every lab works](#how-every-lab-works)
5. [Lab list](#lab-list)
6. [Before you start](#before-you-start)

---

## What is Terraform?

**Terraform** is an **Infrastructure as Code (IaC)** tool by HashiCorp. You describe the infrastructure you want (servers, networks, buckets) in `.tf` files, and Terraform creates, updates or deletes it to match.

```
.tf files (what I want)  ──►  terraform apply  ──►  AWS API  ──►  real EC2, SG, S3 ...
                                     │
                              terraform.tfstate (what exists now)
```

## Why Terraform?

| Without Terraform (console clicks) | With Terraform |
|---|---|
| Click through the console for every server | Write it once in code, run `terraform apply` |
| Hard to repeat the same setup for dev / prod | Same code, different variables |
| No record of who changed what | Code lives in Git: reviewed, versioned |
| Easy to forget to delete things | `terraform destroy` removes everything it created |
| One cloud's console only | One tool for AWS, Azure, GCP and 1000s of providers |

**Declarative:** you say **what** you want, not the steps. Terraform works out the order.

## Theory in short

| Term | Meaning | Example |
|---|---|---|
| **Provider** | plugin that talks to a platform's API | `provider "aws" { region = "us-east-1" }` |
| **terraform block** | Terraform's own settings: providers + versions, backend | `terraform { required_providers { ... } }` |
| **Resource** | something Terraform creates and manages | `resource "aws_instance" "web" { ... }` |
| **Data source** | **reads** something that already exists | `data "aws_ami" "ubuntu" { ... }` |
| **Variable** | input value, so code isn't hardcoded | `var.instance_type` |
| **Output** | prints a value after apply | `output "public_ip" { ... }` |
| **Attribute reference** | use one resource's value in another | `aws_security_group.web.id` |
| **State** (`terraform.tfstate`) | Terraform's record of what it created | local file, or S3 for teams |
| **Backend** | where the state is stored | `backend "s3" { ... }` |
| **Module** | a folder of `.tf` files you reuse | `module "vpc" { source = "./modules/vpc" }` |

**Workflow:**

| Command | Does |
|---|---|
| `terraform init` | downloads providers (and modules), connects the backend |
| `terraform fmt` | formats the code |
| `terraform validate` | checks the syntax |
| `terraform plan` | preview: what will be added / changed / destroyed |
| `terraform apply` | makes the changes (type `yes`) |
| `terraform output` | prints the outputs |
| `terraform destroy` | deletes everything this folder created |

## How every lab works

Every lab folder looks the same:

```
NN-lab-name/
├── README.md     ← goal, concept, step-by-step commands, results, clean up
└── code/         ← the .tf files — run Terraform from here
```

Each README has the same sections: **Goal → Concept → Files → Steps → Check → Clean up → Interview one-liners**.

## Lab list

Do them in order: each one adds one new idea.

| # | Lab | You learn | AWS resources |
|---|---|---|---|
| 00 | [Setup](00-setup/README.md) | IAM user, access key, `aws configure`, install Terraform | IAM user |
| **Basics** | | | |
| 01 | [EC2 + security group](01-ec2-and-security-group/README.md) | first resources, attribute references | EC2, SG |
| 02 | [EC2 with data block, key pair, nginx](02-ec2-data-block-key-pair-nginx/README.md) | data source (AMI lookup), key pair, `user_data`, sensitive output | EC2, key pair, SG + rules |
| 03 | [Resource dependencies](03-resource-dependencies/README.md) | implicit vs explicit (`depends_on`) | EC2, SG, IAM role |
| **AWS services** | | | |
| 04 | [IAM](04-iam/README.md) | users, custom policies, attachments | IAM users, policies |
| 05 | [S3](05-s3/README.md) | bucket, upload object, bucket policy | S3, IAM group |
| 06 | [DynamoDB](06-dynamodb/README.md) | table + items | DynamoDB |
| **Meta-arguments** | | | |
| 07 | [count](07-count/README.md) | many copies by index (and its pitfall) | 3 × EC2 |
| 08 | [for_each](08-for-each/README.md) | many copies by name | 3 × EC2 |
| 09 | [Lifecycle rules](09-lifecycle-rules/README.md) | `create_before_destroy`, `ignore_changes`, `prevent_destroy` | EC2, S3 |
| 10 | [Mutable vs immutable](10-mutable-vs-immutable/README.md) | update in place vs replace | EC2 |
| **State** | | | |
| 11 | [State basics](11-state-basics/README.md) | what's in `terraform.tfstate`, `terraform show` | EC2, SG, IAM role |
| 12 | [Remote state in S3 + locking](12-remote-state-s3-backend/README.md) | S3 backend, `use_lockfile`, `-migrate-state` | S3, EC2 |
| 13 | [State commands](13-state-commands/README.md) | `state list / show / mv / pull / rm` | DynamoDB, S3 |
| 14 | [Cross-stack state](14-cross-stack-state/README.md) | `terraform_remote_state`: one stack reads another's outputs | VPC, subnet, SG, EC2 |
| **Provisioners** | | | |
| 15 | [Provisioners](15-provisioners/README.md) | `remote-exec`, `local-exec`, destroy-time, `on_failure` | EC2, key pair, SG |
| **Projects** | | | |
| 16 | [Conditional EC2 sizing](16-project-conditional-ec2-sizing/README.md) | one code, dev/prod sizes with `.tfvars` + conditional | EC2 |
| 17 | [Modules, multi-environment](17-project-modules-multi-env/README.md) | modules, S3 backend, dev + staging | VPC, SG, IAM, EC2, S3 |

## Before you start

- Do **[00 Setup](00-setup/README.md)** first. Every lab needs a working `aws sts get-caller-identity`.
- Region in the code is `us-east-1` (project 17 uses `eu-west-1`). Change it in `provider.tf` if you want.
- **Cost:** labs use free-tier sizes (`t2.micro` / `t3.micro`), but **always run `terraform destroy`** at the end of each lab.
- S3 bucket names are **global**. Where the code says `CHANGE-ME-...`, put your own unique name.
- Never commit `*.tfstate`, `.terraform/` or private keys. The [.gitignore](.gitignore) already blocks them.
