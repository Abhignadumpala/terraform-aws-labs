# Lab 15 — Provisioners

[← All labs](../README.md) · Theory: [Terraform provisioners](https://github.com/Abhignadumpala/terraform-notes-kodekloud/blob/main/module-08-terraform-provisioners/module-08.4-terraform-provisioners/README.md)

> **Goal:** install nginx over **SSH** with `remote-exec`, write files on your laptop with `local-exec` at create **and** destroy time, and test `on_failure`.

**Before:** [Lab 02](../02-ec2-data-block-key-pair-nginx/README.md) done (same server, but nginx installed a different way).

## Concept

**Provisioner** = runs a command or script when a resource is **created** (or **destroyed**). HashiCorp calls them a **last resort**: prefer `user_data` / images.

| Provisioner | Runs on | Here |
|---|---|---|
| `remote-exec` | the **server**, over SSH (needs a `connection {}` block) | `apt install nginx` |
| `local-exec` | **your laptop** | writes `instance_state.txt` with the IP |
| `when = destroy` | at `terraform destroy` | writes "Destroyed!" |
| `on_failure = continue` | keeps going if the command fails (default `fail` stops) | `null_resource` demo |

**Why a key from `ssh-keygen` here (not `tls_private_key` like Lab 02)?** A destroy-time provisioner's `connection` may only use `self`, so it can't read another resource's key. And `file()` reads at **plan** time, so the key file must exist before `apply`.

## Files

| File | What's inside |
|---|---|
| [provider.tf](code/provider.tf) | aws + **null** providers |
| [main.tf](code/main.tf) | AMI data source, key pair from `web.pub`, SG + rules, EC2 with `remote-exec`, `connection`, 2 × `local-exec` |
| [on_failure_demo.tf](code/on_failure_demo.tf) | `null_resource` with a failing `local-exec` + `on_failure = continue` |
| [outputs.tf](code/outputs.tf) | public IP, AMI used |

## Steps

```bash
cd 15-provisioners/code
ssh-keygen -t rsa -b 4096 -f ./web -N ""     # creates web (private) + web.pub (public)
terraform init
```

### Part 1: remote-exec + local-exec on EC2

I ran this before adding `on_failure_demo.tf`. To repeat it exactly, rename that file to `on_failure_demo.tf.off` first.

| # | Do / check | Result (my run) |
|---|---|---|
| 1 | `terraform apply` | lines prefixed `(remote-exec)` = `apt install nginx` running over SSH → `Creation complete after 51s` → `Apply complete! Resources: 5 added` (key pair, SG, 2 rules, EC2) |
| 2 | `cat instance_state.txt` | `Instance <ip> Created!` (create-time `local-exec`) |
| 3 | `ssh -i web ubuntu@$(terraform output -raw public_ip) systemctl is-active nginx` | `active` |
| 4 | `terraform destroy` | `Destroy complete! Resources: 5 destroyed.` |
| 5 | `cat instance_state.txt` | `Instance <ip> Destroyed!` (destroy-time `local-exec`) |

### Part 2: on_failure

Rename the demo file back to `on_failure_demo.tf`.

| # | Do | Result (my run) |
|---|---|---|
| 1 | delete the `on_failure = continue` line, `terraform apply -target=null_resource.on_failure_demo` | `Error: local-exec provisioner error`; `terraform show` → `(tainted)`; 2nd provisioner never ran |
| 2 | put `on_failure = continue` back, apply again | same error printed, but `Apply complete! Resources: 1 added, 0 changed, 1 destroyed` (tainted one replaced) |
| 3 | `cat on_failure_state.txt` | `second provisioner ran anyway, on_failure = continue worked` |

## Clean up

```bash
terraform destroy
rm web web.pub instance_state.txt on_failure_state.txt
```

## Interview one-liners

- **`remote-exec`** runs on the server (SSH/WinRM); **`local-exec`** runs where Terraform runs.
- Provisioners are a **last resort**: prefer `user_data`, cloud-init or pre-built images (Packer).
- A failed create-time provisioner marks the resource **tainted** → it's replaced on the next apply.
- Destroy-time provisioners can only reference **`self`**.
