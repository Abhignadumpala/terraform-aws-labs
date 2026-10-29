# Lab 13 — State Commands

[← All labs](../README.md) · Theory: [Terraform state commands](https://github.com/Abhignadumpala/terraform-notes-kodekloud/blob/main/module-07-remote-state/module-07.3-terraform-state-commands/README.md)

> **Goal:** use the `terraform state` commands on real resources: list, show, rename (`mv`), download (`pull`) and forget (`rm`).

**Before:** [Lab 12](../12-remote-state-s3-backend/README.md) done (this lab stores its state in that S3 bucket).

## Concept

| Command | Does | Touches AWS? |
|---|---|---|
| `terraform state list` | lists every resource address in state | no |
| `terraform state show <addr>` | all attributes of one resource | no |
| `terraform state mv <old> <new>` | renames an address (after you rename it in code) → **no destroy/recreate** | no |
| `terraform state pull` | prints the remote state JSON | no |
| `terraform state rm <addr>` | Terraform **forgets** the resource; it stays in AWS | no |

## Files

| File | What's inside |
|---|---|
| [provider.tf](code/provider.tf) | aws provider + `backend "s3"` (set your bucket name) |
| [main.tf](code/main.tf) | DynamoDB table `app-config` (`aws_dynamodb_table.app_configuration`) + S3 bucket `reports` (set a unique name) |

## Steps

```bash
cd 13-state-commands/code
```
In `provider.tf` set the bucket from Lab 12; in `main.tf` set a unique `reports` bucket name.

> To practise `mv`, first rename the resource in `main.tf` to `app_config`, apply, then follow step 4.

| # | Command | Result |
|---|---|---|
| 1 | `terraform init` → `terraform apply` | `Apply complete! Resources: 2 added` |
| 2 | `terraform state list` | `aws_dynamodb_table.app_config`, `aws_s3_bucket.reports` |
| 3 | `terraform state show aws_s3_bucket.reports` | bucket ARN, region, tags ... |
| 4 | rename `app_config` → `app_configuration` in `main.tf`, then `terraform state mv aws_dynamodb_table.app_config aws_dynamodb_table.app_configuration` | `Successfully moved 1 object(s).` |
| 5 | `terraform apply` | `Apply complete! Resources: 0 added, 0 changed, 0 destroyed` ← renamed without recreating |
| 6 | `terraform state pull \| jq -r '.resources[] \| select(.name == "app_configuration") \| .instances[].attributes.hash_key'` | `LockID` |
| 7 | `terraform state rm aws_s3_bucket.reports` | `Removed aws_s3_bucket.reports` |
| 8 | `aws s3api head-bucket --bucket <reports-bucket>` | still exists in AWS, but gone from `state list` |

## Clean up

```bash
terraform destroy                          # removes only the DynamoDB table
aws s3 rb s3://<reports-bucket> --force    # the bucket was forgotten by state rm → delete it by hand
```

## Interview one-liners

- **`state mv`** = rename/move a resource address without destroying it (newer way: a `moved {}` block in code).
- **`state rm`** = stop managing a resource without deleting it; you must clean it up yourself later.
- **`state pull`** downloads the remote state as JSON; combine with `jq` to read one value.
- Never edit `terraform.tfstate` by hand; use the `state` commands.
