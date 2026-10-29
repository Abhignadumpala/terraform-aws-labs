# Lab 09 — Lifecycle Rules

[← All labs](../README.md) · Theory: [Lifecycle rules](https://github.com/Abhignadumpala/terraform-notes-kodekloud/blob/main/module-05-working-with-terraform/module-05.3-lifecycle-rules/README.md)

> **Goal:** test the three main `lifecycle` rules on real resources: `create_before_destroy`, `ignore_changes` and `prevent_destroy`.

**Before:** [Lab 00 Setup](../00-setup/README.md) done.

## Concept

| Rule | Does | Use it for |
|---|---|---|
| `create_before_destroy = true` | on replace: create the **new** one first, then delete the old | less downtime |
| `ignore_changes = [tags]` | ignore changes made **outside** Terraform to those attributes | tags/settings other tools change |
| `prevent_destroy = true` | Terraform **refuses** to destroy it | state buckets, databases |

## Files

| File | What's inside |
|---|---|
| [provider.tf](code/provider.tf) | aws + **random** providers |
| [ec2_instance.tf](code/ec2_instance.tf) | 2 AMI data sources (Amazon Linux, Ubuntu) + EC2 with `create_before_destroy` and `ignore_changes = [tags]` |
| [protected_bucket.tf](code/protected_bucket.tf) | `random_id` + S3 bucket with `prevent_destroy` |
| [outputs.tf](code/outputs.tf) | instance ID, IP, AMI, bucket name |

## Steps

```bash
cd 09-lifecycle-rules/code
terraform init
terraform apply        # Apply complete! Resources: 3 added (random_id, bucket, EC2)
```

### Test 1: `create_before_destroy`

1. In `ec2_instance.tf` change `ami = data.aws_ami.amazon_linux.id` → `data.aws_ami.ubuntu.id`.
2. `terraform plan` → `+/- create replacement and then destroy`, `Plan: 1 to add, 0 to change, 1 to destroy`.
3. `terraform apply` → the **new** instance is created first, then the old one deleted → `1 added, 0 changed, 1 destroyed`.

### Test 2: `ignore_changes`

1. Change the tag **outside** Terraform:
   ```bash
   aws ec2 create-tags --resources $(terraform output -raw instance_id) --tags Key=Name,Value=changed-externally
   ```
2. `terraform plan` → `No changes.` ✅ (the rule ignores tags)
3. Remove the `ignore_changes = [tags]` line → `terraform plan` → `Plan: 0 to add, 1 to change` (Terraform wants to put the tag back).
4. Put the line back.

### Test 3: `prevent_destroy`

```bash
terraform destroy
```
```
Plan: 0 to add, 0 to change, 2 to destroy.
Error: Instance cannot be destroyed
Resource aws_s3_bucket.protected has lifecycle.prevent_destroy set ...
```
**Nothing** is destroyed, not even the EC2: the whole plan stops.

## Clean up

1. In `protected_bucket.tf` set `prevent_destroy = false`.
2. `terraform destroy` → `Destroy complete! Resources: 3 destroyed.`
3. Set it back to `true` and change the AMI back to `amazon_linux` for the next person.

## Interview one-liners

- **`create_before_destroy`** avoids downtime on replacement (new resource up before old is removed).
- **`ignore_changes`** stops Terraform reverting attributes changed by other tools or people.
- **`prevent_destroy`** blocks the **entire** destroy plan if any protected resource is in it; it does not protect against deletion in the console.
