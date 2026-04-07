# EKS Terraform Deployment

This Terraform configuration creates:

- One VPC
- Two public subnets
- Two private subnets
- One EKS cluster
- One EKS managed node group with exactly two `m6a.large` worker nodes in the private subnets

## Prerequisites

- Terraform `>= 1.5.0`
- AWS credentials with permission to create VPC, IAM, EC2, and EKS resources
- AWS CLI installed if you want to update local `kubeconfig` after deployment

## Authenticate to AWS

Do not place static credentials in this repository.

Use one of these standard approaches before running Terraform:

### Option 1: AWS CLI profile

```bash
aws configure --profile devops-time-service
export AWS_PROFILE=devops-time-service
```

### Option 2: Environment variables

```bash
export AWS_ACCESS_KEY_ID=YOUR_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=YOUR_SECRET_ACCESS_KEY
export AWS_SESSION_TOKEN=YOUR_SESSION_TOKEN
export AWS_DEFAULT_REGION=us-east-1
```

### Option 3: AWS SSO

```bash
aws configure sso --profile devops-time-service
aws sso login --profile devops-time-service
export AWS_PROFILE=devops-time-service
```

## Deploy

From this directory, run:

```bash
terraform init
terraform plan
terraform apply
```

`terraform.tfvars` contains sane defaults for the required infrastructure. Adjust values there if a different region, CIDR layout, or cluster name is needed.

## Notes

- Worker nodes are attached only to the private subnets.
- A single NAT gateway is enabled by default to keep the configuration simpler and cheaper than one NAT gateway per AZ.
- After apply completes, Terraform outputs an `aws eks update-kubeconfig ...` command you can run to access the cluster.
