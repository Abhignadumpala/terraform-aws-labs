# Lab 02 — EC2 with a Data Block, Key Pair and nginx

[← All labs](../README.md) · Theory: [Data sources](https://github.com/Abhignadumpala/terraform-notes-kodekloud/blob/main/module-05-working-with-terraform/module-05.4-datasources/README.md) · [AWS EC2 with Terraform](https://github.com/Abhignadumpala/terraform-notes-kodekloud/blob/main/module-08-terraform-provisioners/module-08.3-aws-ec2-with-terraform/README.md)

> **Goal:** a real web server: look up the latest Ubuntu AMI with a **data block**, let Terraform create an **SSH key pair**, open SSH with **separate SG rule resources**, install **nginx** on boot with `user_data`, then SSH in.

**Before:** [Lab 00 Setup](../00-setup/README.md) done.

## Concept

| Term | Meaning |
|---|---|
| **Data source** (`data` block) | **reads** something that already exists, creates nothing. Here: the newest Ubuntu 24.04 AMI from Canonical |
| `tls_private_key` | Terraform generates an SSH key (needs the **tls** provider) |
| `aws_key_pair` | uploads the public half to AWS so EC2 accepts it |
| `aws_vpc_security_group_ingress_rule` | one rule = one resource (current AWS provider style), instead of inline `ingress {}` |
| `user_data` | a script EC2 runs **once on first boot** (here: install nginx) |
| `sensitive = true` | hides an output (the private key) from the screen |

```
data.aws_ami.ubuntu ───────────────────────────────┐
tls_private_key ──► aws_key_pair ──────────────────┤
aws_security_group ──► ingress 22 + egress all ────┴──► aws_instance.webserver (user_data: nginx)
```

## Files

| File | What's inside |
|---|---|
| [provider.tf](code/provider.tf) | providers **aws** `~> 5.0` + **tls** `~> 4.0`, region |
| [main.tf](code/main.tf) | AMI data source, key pair, SG + 2 rules, EC2 with `user_data` |
| [outputs.tf](code/outputs.tf) | `public_ip`, `ami_id_used`, `ssh_private_key` (sensitive) |

## Steps

```bash
cd 02-ec2-data-block-key-pair-nginx/code
```

| # | Command | Result |
|---|---|---|
| 1 | `terraform init` | downloads **aws** and **tls** providers |
| 2 | `terraform plan` | `Plan: 6 to add` (key, key pair, SG, 2 rules, EC2) |
| 3 | `terraform apply` → `yes` | `Apply complete! Resources: 6 added`; `ami_id_used` shows the real AMI the data block found |
| 4 | `terraform output -raw ssh_private_key > web.pem && chmod 600 web.pem` | private key saved to a file |
| 5 | `ssh -i web.pem ubuntu@$(terraform output -raw public_ip)` | logged in to the server |
| 6 | `systemctl is-active nginx` | `active` (if `inactive`, wait ~1 min: `user_data` is still running) |
| 7 | `curl -s -o /dev/null -w '%{http_code}\n' localhost` | `200` |

My run: `aws_instance.webserver: Creation complete after 15s`, `Apply complete! Resources: 6 added`, and nginx came up within the first minute after boot (cloud-init finished at ~42 s).

## Check

- **EC2 → Instances** → `webserver` running, key pair `module-08-webserver-key`.
- **EC2 → Security Groups** → `module-08-ssh-access` → inbound 22.

## Clean up

```bash
terraform destroy      # yes
rm web.pem
```

## Interview one-liners

- A **data source** reads existing infrastructure (e.g. latest AMI) instead of hardcoding IDs that go stale.
- `user_data` runs once at **first boot**; changing it later doesn't re-run it on the same instance.
- Mark secrets as **`sensitive = true`**, but remember they're still **plain text in the state file**.
- Separate **SG rule resources** give each rule its own ID, so one rule can change without touching the others.
