# Lab 12 — Remote State in S3 + Locking

[← All labs](../README.md) · Theory: [S3 remote backend and locking](https://github.com/Abhignadumpala/terraform-notes-kodekloud/blob/main/module-07-remote-state/module-07.1-s3-remote-backend-and-locking/README.md) · [State considerations](https://github.com/Abhignadumpala/terraform-notes-kodekloud/blob/main/module-04-terraform-state/module-04.2-terraform-state-considerations/README.md)

> **Goal:** move state from your laptop to an **S3 bucket** with **locking**, so a team can share it safely.

**Before:** [Lab 11](../11-state-basics/README.md) done.

## Concept

| | Local state | Remote state (S3) |
|---|---|---|
| Where | `terraform.tfstate` on your laptop | object in an S3 bucket |
| Team sharing | ❌ | ✅ everyone uses the same state |
| Locking | ❌ two applies can collide | ✅ `use_lockfile = true` writes a `.tflock` file in S3 |
| History | ❌ | ✅ bucket versioning keeps old versions |

**Why 2 folders?** The bucket must exist **before** any config can store state in it. So `bootstrap/` creates the bucket (with local state), then `app/` uses it.

```
bootstrap/  ──apply──►  S3 bucket (versioning, encryption, public access blocked)
                               ▲
app/  ── backend "s3" ─────────┘   state saved at  state-locking-lab/terraform.tfstate
```

## Files

| Folder | What's inside |
|---|---|
| [code/bootstrap/](code/bootstrap) | `random_id` + bucket `tf-state-mutable-immutable-lab-<random>`, versioning, AES256 encryption, public access block; output `state_bucket_name` |
| [code/app/](code/app) | one EC2 + `backend "s3"` with `use_lockfile = true`, `encrypt = true` |
| [code/migration-demo/](code/migration-demo) | EC2 applied with **local** state first, then migrated with `-migrate-state` |

## Steps — Part 1: create the bucket

```bash
cd 12-remote-state-s3-backend/code/bootstrap
terraform init
terraform apply                       # bucket + versioning + encryption + public access block
terraform output state_bucket_name    # copy this name
```

## Steps — Part 2: use it as a backend

1. In `app/provider.tf` replace `CHANGE-ME-state-bucket` with the bucket name.
2. Run:
   ```bash
   cd ../app
   terraform init         # "Successfully configured the backend "s3"!"
   terraform apply        # EC2 created
   ls                     # no terraform.tfstate here — it's in S3
   aws s3 ls s3://<bucket>/state-locking-lab/
   ```
3. **See the lock:** run `terraform apply` in two terminals at once. The second one fails with `Error acquiring the state lock` until the first finishes.

## Steps — Part 3: migrate existing local state

1. In `migration-demo/`, temporarily rename `terraform.tf` → `terraform.tf.off` (no backend = local state).
2. `terraform init && terraform apply` → `Apply complete! Resources: 1 added` (local `terraform.tfstate`).
3. Rename it back, set the bucket name in `terraform.tf`, then:
   ```bash
   terraform init -migrate-state      # answer "yes" to copy local state to S3
   terraform apply                    # Apply complete! Resources: 0 added, 0 changed, 0 destroyed.
   ```
   `0 added` proves Terraform found the existing EC2 through the **migrated** state.

## Clean up

```bash
cd migration-demo && terraform destroy
cd ../app && terraform destroy
cd ../bootstrap && terraform destroy   # last: the bucket (force_destroy = true for this lab)
```

## Interview one-liners

- Remote state in **S3** lets a team share one state; **locking** stops two applies at once.
- Since Terraform **1.10+**, `use_lockfile = true` locks with a file in S3; the older way was a **DynamoDB** table.
- Create the state bucket in a **separate bootstrap** config: you can't store state in a bucket that doesn't exist yet.
- `terraform init -migrate-state` copies existing local state into the new backend.
- Turn on **versioning + encryption + block public access** on every state bucket.
