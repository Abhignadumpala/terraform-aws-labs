# Lab 04 — IAM Users and Policies

[← All labs](../README.md) · Theory: [AWS IAM with Terraform](https://github.com/Abhignadumpala/terraform-notes-kodekloud/blob/main/module-06-aws-services-for-terraform/module-06.4-aws-iam-with-terraform/README.md)

> **Goal:** create two IAM users with Terraform: `priya` with full admin access, and `raj` with a narrow S3 read-only policy.

**Before:** [Lab 00 Setup](../00-setup/README.md) done.

## Concept

| Resource | Is |
|---|---|
| `aws_iam_user` | a person or tool that can log in |
| `aws_iam_policy` | a JSON document: which **Actions** on which **Resources** are allowed |
| `aws_iam_user_policy_attachment` | connects a policy to a user |

IAM is **global**: users and policies aren't tied to a region.

```
priya ◄── attachment ──  AdminUsers  (Action "*", Resource "*")
raj   ◄── attachment ──  S3ReadOnly  (s3:GetObject, s3:ListBucket)
```

## Files

| File | What's inside |
|---|---|
| [provider.tf](code/provider.tf) | aws provider, region (no keys) |
| [iam_user.tf](code/iam_user.tf) | users `priya` and `raj`, with tags |
| [iam_policy.tf](code/iam_policy.tf) | policies `AdminUsers` and `S3ReadOnly` (JSON in a heredoc `<<EOF`) |
| [iam_policy_attachment.tf](code/iam_policy_attachment.tf) | priya → AdminUsers, raj → S3ReadOnly |
| [outputs.tf](code/outputs.tf) | user ARNs, names, policy ARNs |

## Steps

```bash
cd 04-iam/code
```

| # | Command | Result |
|---|---|---|
| 1 | `terraform init` | aws provider downloaded |
| 2 | `terraform plan` | `Plan: 6 to add` (2 users, 2 policies, 2 attachments) |
| 3 | `terraform apply` → `yes` | users, policies and attachments created; outputs show the ARNs |

I built it in two rounds: first `priya` + `AdminUsers` + attachment (`Apply complete! Resources: 3 added`), then added `raj` + `S3ReadOnly` + attachment (`Plan: 3 to add` → `Apply complete! Resources: 3 added`). Terraform only adds what's new.

## Check

- **IAM → Users** → `priya` and `raj`.
- `priya` → **Permissions** → `AdminUsers`; `raj` → `S3ReadOnly`.
- **IAM → Policies** → filter **Customer managed** → both policies.

## Clean up

```bash
terraform destroy      # yes → all 6 removed
```

## Interview one-liners

- An IAM **policy** = JSON of `Effect` / `Action` / `Resource`; attach it to a user, group or role.
- **Least privilege:** `raj` gets only `s3:GetObject` and `s3:ListBucket`, not `s3:*`.
- IAM is a **global** service; the provider region doesn't matter for it.
- Prefer attaching policies to **groups** or **roles** rather than individual users in real teams.
