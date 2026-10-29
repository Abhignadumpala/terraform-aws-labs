# Lab 00 — Setup: Connect Terraform to AWS

[← All labs](../README.md) · Theory: [Programmatic access](https://github.com/Abhignadumpala/terraform-notes-kodekloud/blob/main/module-06-aws-services-for-terraform/module-06.3-programmatic-access/README.md) · [IAM](https://github.com/Abhignadumpala/terraform-notes-kodekloud/blob/main/module-06-aws-services-for-terraform/module-06.1-introduction-to-iam/README.md)

> **Goal:** get a laptop ready so Terraform can create resources in your AWS account. Do this **once**; every other lab needs it.

## Concept

Terraform creates AWS resources by calling the AWS API **as an IAM user**. It has **no permissions of its own**.

```
 ① aws configure                       ② terraform apply
 (access key + secret)                 (reads your .tf files)
        │                                      │
        ▼                                      ▼
 ~/.aws/credentials ──── read by ────► AWS provider plugin
                                               │  API call signed with the IAM user's keys
                                               ▼
                                     AWS checks the user's IAM policies
                                     allowed ✅ → resource created
                                     denied  ❌ → AccessDenied
```

| | Authentication | Authorization |
|---|---|---|
| Question | **Who are you?** | **What can you do?** |
| Here | the IAM user's **access key + secret** | the **IAM policies** on that user |

The user needs permission for the **whole lifecycle**: read (for `plan`), create/update (for `apply`), delete (for `destroy`).

## Step 1: Create an IAM user

1. AWS console → **IAM** → **Users** → **Create user**.
2. Name: `terraform-user`.
3. **Attach policies directly** → **`AdministratorAccess`** (fine for learning; in real jobs give only what's needed).
4. **Create user**.

## Step 2: Create an access key

1. IAM → Users → `terraform-user` → **Security credentials** → **Create access key**.
2. Use case: **Command Line Interface (CLI)** → **Create**.
3. Save the **Access key ID** and **Secret access key** (the secret is shown only once).

> ⚠️ The access key is like a password. Never put it in a `.tf` file or push it to GitHub.

## Step 3: Install the AWS CLI (Ubuntu/Linux)

```bash
sudo apt-get install -y unzip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version
```

## Step 4: Configure the credentials

```bash
aws configure
```
```
AWS Access Key ID [None]: <your-access-key-id>
AWS Secret Access Key [None]: <your-secret-access-key>
Default region name [None]: us-east-1
Default output format [None]: json
```

| File created | Holds |
|---|---|
| `~/.aws/credentials` | access key + secret |
| `~/.aws/config` | region + output format |

## Step 5: Install Terraform (Ubuntu)

```bash
wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform -y
```

## Check

| Command | You should see |
|---|---|
| `aws --version` | `aws-cli/2.x.x` |
| `aws sts get-caller-identity` | your account ID and `user/terraform-user` |
| `terraform version` | `Terraform v1.x.x` (1.11+ needed for lab 17's S3 locking) |

All three work → you're ready for [Lab 01](../01-ec2-and-security-group/README.md).

## How Terraform uses this

In every lab, `provider.tf` only sets the **region**:
```hcl
provider "aws" {
  region = "us-east-1"
}
```
There are no keys in the code. The AWS provider reads `~/.aws/credentials`, the same as the CLI.

## If something fails

| Error | Fix |
|---|---|
| `No valid credential sources found` | run `aws configure`, check with `aws sts get-caller-identity` |
| `UnauthorizedOperation` / `AccessDenied` | the IAM user is missing a permission → add it in IAM |
| `Missing required argument: region` | add `region` in the `provider "aws"` block |

## Interview one-liners

- **Authentication** = access key proves who I am; **authorization** = IAM policies decide what I can do.
- Terraform has **no AWS permissions of its own**; it uses the credentials it's given.
- **No keys in `.tf` files**: the provider reads `~/.aws/credentials`.
- In production: **least privilege**, and short-lived credentials (IAM roles, SSO, OIDC in CI) instead of long-lived keys.
