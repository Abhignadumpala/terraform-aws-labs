# Lab 07 — count: Many EC2 Servers by Index

[← All labs](../README.md) · Theory: [count](https://github.com/Abhignadumpala/terraform-notes-kodekloud/blob/main/module-05-working-with-terraform/module-05.6-count/README.md)

> **Goal:** create 3 EC2 servers from one resource block with `count`, then remove the first name and see **count's index-shifting problem** for real.

**Before:** [Lab 00 Setup](../00-setup/README.md) done.

## Concept

**`count`** = a meta-argument that makes N copies of a resource. Each copy is addressed by **position**: `aws_instance.web[0]`, `[1]`, `[2]`.

```hcl
count = length(var.web_server_names)          # 3
Name  = var.web_server_names[count.index]     # web-prod-1, web-prod-2, web-prod-3
```

**The pitfall:** remove the **first** item from the list and every position moves up by one:

| Address | Before | After removing `web-prod-1` |
|---|---|---|
| `web[0]` | web-prod-1 | web-prod-**2** → renamed |
| `web[1]` | web-prod-2 | web-prod-**3** → renamed |
| `web[2]` | web-prod-3 | gone → **destroyed** |

You wanted to delete web-prod-1, but Terraform renames two servers and deletes the **last** one.

## Files

| File | What's inside |
|---|---|
| [provider.tf](code/provider.tf) | aws provider, region |
| [data.tf](code/data.tf) | Ubuntu 20.04 AMI lookup |
| [variables.tf](code/variables.tf) | `web_server_names` = `["web-prod-1", "web-prod-2", "web-prod-3"]` |
| [ec2_instances.tf](code/ec2_instances.tf) | `aws_instance.web` with `count` |
| [outputs.tf](code/outputs.tf) | all IDs (`web[*].id`), names by index, first ID |

## Steps

```bash
cd 07-count/code
```

| # | Do | Result (my run) |
|---|---|---|
| 1 | `terraform init` → `terraform apply` | `Plan: 3 to add` → `Apply complete! Resources: 3 added` |
| 2 | `terraform output web_server_names_by_index` | `0 = web-prod-1`, `1 = web-prod-2`, `2 = web-prod-3` |
| 3 | In `variables.tf`, delete `"web-prod-1"` from the list | |
| 4 | `terraform plan` | `Plan: 0 to add, 2 to change, 1 to destroy` ← the pitfall |
| 5 | `terraform apply` | `Apply complete! Resources: 0 added, 2 changed, 1 destroyed` |
| 6 | Check names again | the remaining 2 servers got **new Name tags**; the old `web[2]` was destroyed |

## Clean up

```bash
terraform destroy      # Destroy complete! Resources: 2 destroyed.
```
Put `"web-prod-1"` back in `variables.tf` so the next person starts from 3.

## Interview one-liners

- `count` addresses copies by **index**; removing an item from the middle/start **shifts** the others.
- Use `count` for **identical** copies, or `count = var.create ? 1 : 0` to switch a resource on/off.
- For items with **names**, use `for_each` ([Lab 08](../08-for-each/README.md)).
