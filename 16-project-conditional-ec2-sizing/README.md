# Project 16 — Conditional EC2 Sizing (dev vs prod)

[← All labs](../README.md) · Full write-up: [conditional-ec2-sizing](https://github.com/Abhignadumpala/terraform-notes-kodekloud/blob/main/terraform-projects/conditional-ec2-sizing/README.md)

> **Goal:** one piece of code that creates a **small** EC2 for dev and a **bigger** one for prod, chosen by a variable file.

**Before:** [Lab 00 Setup](../00-setup/README.md) done.

## Concept

**Conditional expression:** `condition ? value_if_true : value_if_false`

```hcl
instance_type = var.environment == "prod" ? "t2.medium" : "t2.micro"
```

**`.tfvars` file** = a file of variable values, picked with `--var-file`:

| File | `environment` | Instance type |
|---|---|---|
| [dev.tfvars](code/dev.tfvars) | `dev` | `t2.micro` |
| [prod.tfvars](code/prod.tfvars) | `prod` | `t2.medium` |

## Files

| File | What's inside |
|---|---|
| [provider.tf](code/provider.tf) | aws provider, region |
| [variables.tf](code/variables.tf) | `environment`, `instance_name` (no defaults → must come from a tfvars file) |
| [data.tf](code/data.tf) | Amazon Linux 2 AMI lookup |
| [ec2_instance.tf](code/ec2_instance.tf) | EC2 with the conditional `instance_type` |
| [outputs.tf](code/outputs.tf) | instance ID, instance type, environment |

## Steps

```bash
cd 16-project-conditional-ec2-sizing/code
terraform init
```

| # | Command | Result (my run) |
|---|---|---|
| 1 | `terraform plan` (no var file) | asks `Enter a value:` for `var.environment` → you need `--var-file` |
| 2 | `terraform apply --var-file=dev.tfvars` | `Apply complete! Resources: 1 added`, `instance_type = "t2.micro"` |
| 3 | `terraform destroy --var-file=dev.tfvars` | dev removed |
| 4 | `terraform apply --var-file=prod.tfvars` | `Apply complete! Resources: 1 added`, `instance_type = "t2.medium"` |
| 5 | `terraform destroy --var-file=prod.tfvars` | prod removed |

> One folder = **one state**. Applying prod while dev exists would **change** the dev server into prod. Keep environments apart with **workspaces** (`terraform workspace new dev`) or separate folders — see [Project 17](../17-project-modules-multi-env/README.md).

## Interview one-liners

- `cond ? a : b` picks a value from a variable: same code, different sizes per environment.
- `--var-file=dev.tfvars` loads variable values; `terraform.tfvars` is loaded automatically.
- Different environments need **separate state** (workspaces or folders), not just different tfvars.
