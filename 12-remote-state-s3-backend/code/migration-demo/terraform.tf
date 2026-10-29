# Backend config kept separate from main.tf, on purpose - a config block
# this important is easier to find and reason about in its own file.

terraform {
  backend "s3" {
    bucket       = "CHANGE-ME-state-bucket" # same bucket as app/ (from bootstrap)
    key          = "migration-demo/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}
