# Bootstrap

Creates the prerequisites that Terraform itself needs to run:
- S3 buckets for remote state (dev + prod)
- DynamoDB tables for state locking (dev + prod)
- GitHub Actions OIDC provider + IAM role

## When to run

Once, from a developer laptop with admin AWS credentials.
Never run from CI/CD. Never change the backend from `local`.

## Steps

1. Edit `terraform.tfvars` and fill in your `github_org` and `github_repo`
2. Make sure your local AWS credentials have AdministratorAccess
3. Run:

```bash
terraform init
terraform apply
```

4. Copy the `role_arn` output and add it to your GitHub repo:
   **Settings → Secrets → Actions → New secret → `AWS_ROLE_ARN`**

## After bootstrap

All other infrastructure is managed by `envs/dev` and `envs/prod` via GitHub Actions.
You should never need to touch this folder again unless you're rebuilding from scratch.
