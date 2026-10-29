# Lab 06 — DynamoDB Table and Items

[← All labs](../README.md) · Theory: [DynamoDB with Terraform](https://github.com/Abhignadumpala/terraform-notes-kodekloud/blob/main/module-06-aws-services-for-terraform/module-06.9-dynamodb-with-terraform/README.md)

> **Goal:** create a DynamoDB table and put two employee records into it with Terraform.

**Before:** [Lab 00 Setup](../00-setup/README.md) done.

## Concept

**DynamoDB** = AWS's serverless NoSQL (key-value) database.

| Term | Meaning |
|---|---|
| **Hash key** (partition key) | the unique ID of each item; here `employee_id` (number) |
| `attribute {}` | declare **only the key** attributes; other fields are free-form |
| `PAY_PER_REQUEST` | on-demand billing: pay per read/write, no capacity to set |
| `aws_dynamodb_table_item` | one item (row), written in DynamoDB JSON: `{"N": "1"}` = number, `{"S": "abdul"}` = string |

```
employee_data_tf
 ├── employee_id 1 → abdul, 33, manager
 └── employee_id 2 → sara, 27, analyst
```

## Files

| File | What's inside |
|---|---|
| [provider.tf](code/provider.tf) | aws provider, region |
| [dynamodb_table.tf](code/dynamodb_table.tf) | table `employee_data_tf`, hash key `employee_id`, on-demand |
| [dynamodb_table_item.tf](code/dynamodb_table_item.tf) | items `abdul` and `sara` |
| [outputs.tf](code/outputs.tf) | table name |

## Steps

```bash
cd 06-dynamodb/code
terraform init
terraform apply        # yes
```

My run, in two rounds:

| # | Added | Result |
|---|---|---|
| 1 | table | `Plan: 1 to add` → `Apply complete! Resources: 1 added` |
| 2 | 2 items | `Plan: 2 to add` → `Apply complete! Resources: 2 added` |

## Check

```bash
aws dynamodb scan --table-name employee_data_tf --query 'Items[].name.S'
```
Console: **DynamoDB → Tables → employee_data_tf → Explore table items**: 2 items.

## Clean up

```bash
terraform destroy      # yes
```

## Interview one-liners

- In `aws_dynamodb_table`, declare **only key attributes** in `attribute {}`; other fields don't need a schema.
- `PAY_PER_REQUEST` = on-demand; `PROVISIONED` = you set read/write capacity.
- `hash_key = aws_dynamodb_table.x.hash_key` in an item keeps it tied to the table's key, not hardcoded.
- DynamoDB with a `LockID` key was the classic Terraform **state lock** table (now S3 `use_lockfile` can replace it).
