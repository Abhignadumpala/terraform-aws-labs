# Lab 10 — Mutable vs Immutable Changes

[← All labs](../README.md) · Theory: [Mutable vs immutable](https://github.com/Abhignadumpala/terraform-notes-kodekloud/blob/main/module-05-working-with-terraform/module-05.2-mutable-vs-immutable-infrastructure/README.md)

> **Goal:** see which changes Terraform makes **in place** (mutable) and which force it to **replace** the server (immutable).

**Before:** [Lab 00 Setup](../00-setup/README.md) done.

## Concept

| | Mutable (update in place) | Immutable (replace) |
|---|---|---|
| Plan symbol | `~ update in-place` | `-/+ must be replaced` |
| Example | change a **tag** | change the **AMI** |
| Server ID | stays the same | **new** ID |

Terraform's default for a replacement is **destroy first, then create** (Lab 09 shows how to flip that with `create_before_destroy`).

## Files

| File | What's inside |
|---|---|
| [provider.tf](code/provider.tf) | aws provider, region |
| [ec2_instance.tf](code/ec2_instance.tf) | 2 AMI data sources + EC2 (starts as Amazon Linux, tag `web-server-v1`) |
| [outputs.tf](code/outputs.tf) | instance ID, AMI, IP, tags |

## Steps

```bash
cd 10-mutable-vs-immutable/code
terraform init
terraform apply        # baseline: 1 EC2, note the instance_id output
```

### Part 1: mutable (tag)

1. In `ec2_instance.tf` change `Name = "web-server-v1"` → `"web-server-v2"`.
2. `terraform plan` → `~ update in-place`, `Plan: 0 to add, 1 to change, 0 to destroy`.
3. `terraform apply` → `Apply complete! Resources: 0 added, 1 changed, 0 destroyed`. **Same** `instance_id`.

### Part 2: immutable (AMI)

1. Change `ami = data.aws_ami.amazon_linux.id` → `data.aws_ami.ubuntu.id`.
2. `terraform plan` → `-/+ must be replaced`, `ami ... # forces replacement`, `Plan: 1 to add, 0 to change, 1 to destroy`.
3. `terraform apply` → `Apply complete! Resources: 1 added, 0 changed, 1 destroyed`. **New** `instance_id`.

## Clean up

```bash
terraform destroy
```
Set the AMI back to `amazon_linux` and the tag back to `web-server-v1`.

## Interview one-liners

- `# forces replacement` in a plan = that attribute can't change in place, so the resource is **recreated**.
- Immutable infrastructure = replace servers instead of patching them → no configuration drift.
- Always read the plan for `-/+` before applying: replacement means a **new** server (new IP, data on it lost).
