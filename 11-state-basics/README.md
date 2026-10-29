# Lab 11 — State Basics

[← All labs](../README.md) · Theory: [Introduction to state](https://github.com/Abhignadumpala/terraform-notes-kodekloud/blob/main/module-04-terraform-state/module-04.0-introduction-to-terraform-state/README.md)

> **Goal:** look inside `terraform.tfstate`, see how Terraform compares **code ↔ state ↔ real AWS**, and use the state to find a real mistake.

**Before:** [Lab 00 Setup](../00-setup/README.md) done.

## Concept

**State** (`terraform.tfstate`) = Terraform's JSON record of every resource it created, with all its attributes (IDs, IPs, ...).

```
.tf code (desired)  ──┐
                      ├──► terraform plan = difference ──► apply ──► updates AWS + state
tfstate (last known) ─┘
```

| File | Is |
|---|---|
| `terraform.tfstate` | current state (created after the first `apply`) |
| `terraform.tfstate.backup` | the previous version |

> State can hold **secrets** in plain text. Never commit it; for teams keep it in S3 ([Lab 12](../12-remote-state-s3-backend/README.md)).

## Files

| File | What's inside |
|---|---|
| [provider.tf](code/provider.tf) | aws provider, region |
| [variables.tf](code/variables.tf) | `instance_type` = `t2.micro` |
| [main.tf](code/main.tf) | AMI data source, IAM role + instance profile, security group `web-security-group` (port 80), EC2 `my-web-server` |

## Steps

```bash
cd 11-state-basics/code
```

| # | Command | What you see |
|---|---|---|
| 1 | `ls` | no `terraform.tfstate` yet |
| 2 | `terraform init` → `terraform apply` | resources created |
| 3 | `ls` | `terraform.tfstate` now exists |
| 4 | `terraform state list` | `data.aws_ami.amazon_linux_2`, `aws_iam_role...`, `aws_iam_instance_profile...`, `aws_security_group.web_sg`, `aws_instance.web_server` |
| 5 | `terraform show` | every attribute, readable |
| 6 | `terraform state show aws_instance.web_server` | one resource: look at `vpc_security_group_ids` |

My run: first apply with SG + EC2 → `Apply complete! Resources: 2 added`. Then I added the IAM role + profile and the `iam_instance_profile` line → `Apply complete! Resources: 2 added, 1 changed` (the EC2 was **updated in place**, not replaced).

## Exercise: find the bug with the state

In step 6, `vpc_security_group_ids` shows the **default** SG, not `web-security-group`. The SG was created but **never attached**: `aws_instance.web_server` has no `vpc_security_group_ids` line.

**Fix:** add to `aws_instance.web_server`:
```hcl
vpc_security_group_ids = [aws_security_group.web_sg.id]
```
`terraform plan` → `1 to change` → `terraform apply` → `state show` now lists `web-security-group`.

## Clean up

```bash
terraform destroy
ls                     # tfstate stays, but now holds no resources
```

## Interview one-liners

- State maps **code to real resources** (resource address ↔ AWS ID); without it Terraform can't know what it manages.
- `plan` compares **code vs state**, after refreshing state from AWS.
- State can contain **secrets** → don't commit it; use an encrypted remote backend.
- `terraform state show <address>` is the quickest way to check what really got configured.
