# Lab 03 — Resource Dependencies (Implicit vs Explicit)

[← All labs](../README.md) · Theory: [Resource dependencies](https://github.com/Abhignadumpala/terraform-notes-kodekloud/blob/main/module-03-terraform-basics/module-03.8-resource-dependencies-in-terraform/README.md)

> **Goal:** see how Terraform decides **what to create first**: automatically from references (implicit), or forced with `depends_on` (explicit).

**Before:** [Lab 00 Setup](../00-setup/README.md) done.

## Concept

| | Implicit dependency | Explicit dependency |
|---|---|---|
| How | one resource **references** another (`aws_security_group.web.id`) | `depends_on = [ ... ]` |
| When | almost always | only when there's **no reference** but order still matters |
| Example here | EC2 uses the SG's ID | EC2 must wait until an IAM **policy** is attached to its role |

```
implicit/   aws_security_group.web ──.id──► aws_instance.web_server

explicit/   aws_iam_role ──► aws_iam_role_policy ─────depends_on─────┐
                    └──────► aws_iam_instance_profile ──.name──► aws_instance.app_server
```

The EC2 references the **instance profile**, but nothing references the **policy**. Without `depends_on`, the server could boot before its permissions exist.

## Files

| Folder | Files |
|---|---|
| [code/implicit/](code/implicit) | `provider.tf`, `security_group.tf`, `ec2_instance.tf` (AMI data source + `vpc_security_group_ids`), `outputs.tf` |
| [code/explicit/](code/explicit) | `provider.tf`, `iam_role.tf` (role, policy, instance profile), `ec2_instance.tf` (`depends_on`), `outputs.tf` |

## Steps — Part 1: implicit

```bash
cd 03-resource-dependencies/code/implicit
terraform init
terraform apply        # yes
```

My real order:
```
aws_security_group.web: Creation complete after 4s
aws_instance.web_server: Creating...          ← starts only after the SG is done
aws_instance.web_server: Creation complete after 14s
```
```bash
terraform destroy      # Destroy complete! Resources: 2 destroyed.
```

## Steps — Part 2: explicit

```bash
cd ../explicit
terraform init
terraform apply        # yes
```

My real order:
```
aws_iam_role.ec2_role: Creation complete after 1s
aws_iam_role_policy.ec2_s3_read: Creating...
aws_iam_instance_profile.ec2_profile: Creating...
aws_iam_role_policy.ec2_s3_read: Creation complete after 0s
aws_iam_instance_profile.ec2_profile: Creation complete after 6s
aws_instance.app_server: Creating...          ← waits for BOTH profile and policy
Apply complete! Resources: 4 added, 0 changed, 0 destroyed.
```
```bash
terraform destroy      # Destroy complete! Resources: 4 destroyed.
```

**See the graph:** `terraform graph` prints the dependency tree.

## Interview one-liners

- **Implicit** dependency = created automatically by an attribute reference; prefer it.
- **Explicit** `depends_on` = only for hidden dependencies Terraform can't see (e.g. an IAM policy the app needs at boot).
- Terraform creates independent resources **in parallel** (default 10 at a time) and destroys in **reverse** order.
