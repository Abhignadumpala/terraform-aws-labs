# Lab 14 — Cross-Stack State (terraform_remote_state)

[← All labs](../README.md) · Theory: [Cross-stack state sharing](https://github.com/Abhignadumpala/terraform-notes-kodekloud/blob/main/module-07-remote-state/module-07.2-cross-stack-state-sharing/README.md)

> **Goal:** split infrastructure into two separate Terraform projects: a **network** stack and a **compute** stack. The compute stack reads the network stack's outputs straight from its state in S3.

**Before:** [Lab 12](../12-remote-state-s3-backend/README.md) done.

## Concept

**`data "terraform_remote_state"`** = reads the **outputs** of another Terraform project's state.

```
bootstrap/  → S3 bucket (shared backend)
                 │
network/  ── state: network/terraform.tfstate ── outputs: vpc_id, subnet_id, security_group_id
                 │
compute/  ── data "terraform_remote_state" "network" ──► subnet_id + security_group_id ──► EC2
             state: compute/terraform.tfstate
```

**Why split?** Network changes rarely, compute often. Separate stacks = smaller plans, less risk, different teams can own each.

## Files

| Folder | What's inside |
|---|---|
| [code/bootstrap/](code/bootstrap) | state bucket `tf-remote-state-lab-<random>` + versioning, encryption, public access block |
| [code/network/](code/network) | VPC `10.0.0.0/16`, internet gateway, public subnet, route table + association, SG (SSH); outputs `vpc_id`, `subnet_id`, `security_group_id` |
| [code/compute/](code/compute) | `terraform_remote_state` → EC2 in the network's subnet with its SG; output `vpc_id_from_remote_state` |

## Steps

| # | Where | Do | Result (my run) |
|---|---|---|---|
| 1 | `code/bootstrap` | `terraform init && terraform apply` | `Apply complete! Resources: 5 added`; copy `state_bucket_name` |
| 2 | `network/provider.tf`, `compute/provider.tf`, `compute/main.tf` | replace `CHANGE-ME-state-bucket` with that name (3 places) | |
| 3 | `code/network` | `terraform init && terraform apply` | `Apply complete! Resources: 6 added` |
| 4 | `code/compute` | `terraform init && terraform apply` | `Apply complete! Resources: 1 added` |
| 5 | `code/compute` | `terraform output vpc_id_from_remote_state` | same VPC ID as `network`'s `vpc_id` output ✅ |

## Check

```bash
aws s3 ls s3://<bucket> --recursive     # network/terraform.tfstate and compute/terraform.tfstate
```
Console: the EC2 `module-07-compute-lab` sits in subnet `module-07-network-lab-public`.

## Clean up (reverse order)

```bash
cd compute && terraform destroy
cd ../network && terraform destroy
cd ../bootstrap && terraform destroy
```
Destroy **compute first**: the network can't be deleted while the EC2 still uses its subnet and SG.

## Interview one-liners

- `terraform_remote_state` reads **only outputs** of another state; expose what other stacks need as `output`s.
- Split stacks by **rate of change and ownership** (network vs app).
- Destroy in **reverse dependency order**: consumers (compute) before producers (network).
- Alternative without state access: look the values up with data sources (`data "aws_vpc"` by tag).
