# Lab 01 — EC2 + Security Group

[← All labs](../README.md) · Theory: [Resource attributes](https://github.com/Abhignadumpala/terraform-notes-kodekloud/blob/main/module-03-terraform-basics/module-03.7-resource-attributes/module-03.7-resource-attributes.md)

> **Goal:** create your first two AWS resources — a security group and an EC2 server — and link them with an **attribute reference**.

**Before:** [Lab 00 Setup](../00-setup/README.md) done.

## Concept

**Attribute reference** = using a value of one resource inside another: `<type>.<name>.<attribute>`.

```hcl
vpc_security_group_ids = [aws_security_group.allow_ssh.id]
```

Because EC2 uses the SG's `id`, Terraform knows: **create SG first, then EC2**. No hardcoded IDs.

```
aws_security_group.allow_ssh  ──.id──►  aws_instance.web_server
     (22, 80, 443 in)                      (t2.micro, tag web-server)
```

## Files

| File | What's inside |
|---|---|
| [provider.tf](code/provider.tf) | `terraform {}` (aws provider `~> 5.0`) + `provider "aws"` (region) |
| [security_group.tf](code/security_group.tf) | SG `allow-ssh`: inbound 22, 80, 443; all outbound |
| [ec2_instance.tf](code/ec2_instance.tf) | `aws_instance.web_server`, linked to the SG |
| [outputs.tf](code/outputs.tf) | SG ID, instance ID, public IP, linked SG IDs |

> The AMI ID in `ec2_instance.tf` (`ami-054d6a336762e438e`) is for **us-east-1**. In another region, copy an AMI ID from EC2 → Launch instance. (Lab 02 shows how to look it up automatically.)

## Steps

```bash
cd 01-ec2-and-security-group/code
```

| # | Command | Result |
|---|---|---|
| 1 | `terraform init` | downloads the AWS provider |
| 2 | `terraform validate` | `Success! The configuration is valid.` |
| 3 | `terraform plan` | `aws_security_group.allow_ssh` and `aws_instance.web_server` will be created |
| 4 | `terraform apply` → `yes` | SG created first, then EC2 → `Apply complete! Resources: 2 added` |
| 5 | `terraform output` | instance ID, public IP, SG ID |

## Check

- **EC2 → Instances** → `web-server` running → **Security** tab shows `allow-ssh`.
- **EC2 → Security Groups** → `allow-ssh` → inbound rules 22, 80, 443.
- `linked_sg_id` output = `security_group_id` output → the link worked.

## Clean up

```bash
terraform destroy      # yes → Destroy complete! Resources: 2 destroyed.
```

## Interview one-liners

- **Attribute reference** `aws_security_group.allow_ssh.id` passes one resource's value to another, no hardcoding.
- A reference creates an **implicit dependency**: Terraform creates the SG before the EC2.
- `0.0.0.0/0` on port 22 is for labs only; in real setups allow SSH from your IP or use SSM.
