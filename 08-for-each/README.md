# Lab 08 — for_each: Many EC2 Servers by Name

[← All labs](../README.md) · Theory: [for_each](https://github.com/Abhignadumpala/terraform-notes-kodekloud/blob/main/module-05-working-with-terraform/module-05.7-for-each/README.md)

> **Goal:** same 3 servers as [Lab 07](../07-count/README.md), but with `for_each`, and prove that removing one name deletes **only that server**.

**Before:** [Lab 00 Setup](../00-setup/README.md) done.

## Concept

**`for_each`** = makes one copy per item of a **set** or **map**. Each copy is addressed by **key**, not position:

```hcl
for_each = var.web_server_names        # set(string)
Name     = each.value                  # each.key = each.value for a set
```

| Address | Removing `web-prod-1` |
|---|---|
| `web["web-prod-1"]` | **destroyed** ✅ |
| `web["web-prod-2"]` | untouched |
| `web["web-prod-3"]` | untouched |

| | count | for_each |
|---|---|---|
| Address | `web[0]` | `web["web-prod-1"]` |
| Remove one item | others **shift** → renames/destroys | only that item changes |
| Input | number / list | **set** or **map** (use `toset()` for a list) |

## Files

| File | What's inside |
|---|---|
| [provider.tf](code/provider.tf) | aws provider, region |
| [data.tf](code/data.tf) | Ubuntu 20.04 AMI lookup |
| [variables.tf](code/variables.tf) | `web_server_names` as `set(string)` with 3 names |
| [ec2_instances.tf](code/ec2_instances.tf) | `aws_instance.web` with `for_each` |
| [outputs.tf](code/outputs.tf) | IDs by name, names by key, ID of `web-prod-2` |

## Steps

```bash
cd 08-for-each/code
```

| # | Do | Result (my run) |
|---|---|---|
| 1 | `terraform init` → `terraform apply` | `Plan: 3 to add` → `Apply complete! Resources: 3 added` |
| 2 | `terraform state list` | `aws_instance.web["web-prod-1"]`, `["web-prod-2"]`, `["web-prod-3"]` |
| 3 | In `variables.tf`, delete `"web-prod-1"` | |
| 4 | `terraform plan` | `Plan: 0 to add, 0 to change, 1 to destroy` ← only web-prod-1 |
| 5 | `terraform apply` | `Apply complete! Resources: 0 added, 0 changed, 1 destroyed` |

Compare with Lab 07: there, the same change gave `2 to change, 1 to destroy`.

## Clean up

```bash
terraform destroy      # yes
```
Put `"web-prod-1"` back in `variables.tf`.

## Interview one-liners

- `for_each` addresses copies by **key**, so adding/removing one item never touches the others.
- `for_each` needs a **set or map**; wrap a list with `toset()`.
- Rule: **identical copies → `count`; named / distinct items → `for_each`**.
