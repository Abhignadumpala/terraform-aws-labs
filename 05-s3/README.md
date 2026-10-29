# Lab 05 — S3 Bucket, Object and Bucket Policy

[← All labs](../README.md) · Theory: [S3 with Terraform](https://github.com/Abhignadumpala/terraform-notes-kodekloud/blob/main/module-06-aws-services-for-terraform/module-06.6-s3-with-terraform/README.md)

> **Goal:** create an S3 bucket, upload a file into it, and give a finance team access with a **bucket policy**.

**Before:** [Lab 00 Setup](../00-setup/README.md) done.

## Concept

| Resource | Is |
|---|---|
| `aws_s3_bucket` | the bucket (name must be **globally unique**) |
| `aws_s3_object` | a file uploaded into the bucket |
| `aws_s3_bucket_policy` | **resource-based** policy on the bucket: who may access it |
| `data "aws_caller_identity"` | reads your account ID → used to make the bucket name unique |
| `data "aws_iam_group"` | reads the group's members → their ARNs go into the policy |

```
finance-<account-id>  (bucket)
   ├── finance-2020.txt  (object)
   └── bucket policy: allow  ← members of IAM group finance-analysts (user meena)
```

> A bucket policy **can't** name an IAM group as `Principal`, only users/roles. So the code reads the group's **members** and puts their ARNs in the policy.

## Files

| File | What's inside |
|---|---|
| [provider.tf](code/provider.tf) | aws provider, region |
| [s3_bucket.tf](code/s3_bucket.tf) | caller-identity data source + bucket `finance-<account-id>` |
| [s3_object.tf](code/s3_object.tf) | uploads [finance-2020.txt](code/finance-2020.txt) |
| [iam_group.tf](code/iam_group.tf) | user `meena`, group `finance-analysts`, membership |
| [s3_bucket_policy.tf](code/s3_bucket_policy.tf) | group data source + bucket policy |
| [outputs.tf](code/outputs.tf) | bucket name/ARN, object key, group ARN, member ARNs |

## Steps

```bash
cd 05-s3/code
terraform init
terraform apply        # yes
```

I applied it piece by piece, one file at a time, to see each part:

| # | Added | Result |
|---|---|---|
| 1 | bucket | `Apply complete! Resources: 1 added` |
| 2 | object (file upload) | `Resources: 1 added` |
| 3 | IAM user + group + membership | `Resources: 3 added` |
| 4 | bucket policy | `Resources: 1 added` |

Applying everything at once gives the same 6 resources in one go.

## Check

```bash
terraform output
aws s3 ls s3://$(terraform output -raw bucket_name)      # finance-2020.txt
aws s3api get-bucket-policy --bucket $(terraform output -raw bucket_name)
```
Console: **S3** → `finance-<account-id>` → **Objects** and **Permissions → Bucket policy**.

## Clean up

```bash
terraform destroy      # yes (Terraform deletes the object first, then the bucket)
```

## Interview one-liners

- S3 bucket names are **global**; add the account ID or a random suffix to keep them unique.
- **Bucket policy** = resource-based (on the bucket); **IAM policy** = identity-based (on a user/role).
- IAM **groups can't be a `Principal`** in a bucket policy; use users, roles or accounts.
- `aws_caller_identity` gives the current account ID without hardcoding it.
