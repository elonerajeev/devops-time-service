# SimpleTimeService — Particle41 DevOps Challenge

A minimal Node.js microservice that returns the current timestamp and visitor IP, deployed on AWS EKS via Terraform and Kubernetes.

## Repository Structure

```
devops-time-service/
├── web-app/                  # Node.js app + Dockerfile
├── terraform/                # VPC + EKS infrastructure (IaC)
│   └── modules/
│       ├── vpc/
│       └── eks/
|       ├── main.tf
│       └── variables.tf
|       ├── outputs.tf
│       └── terraform.tfvars
├── .github/workflows/        # GitHub Actions CI/CD pipeline
└── microservice.yml          # Kubernetes Deployment + Service 
|__ README.md  # project descriptions

```

## Prerequisites

- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [Terraform v1.5.0+](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Docker](https://docs.docker.com/get-docker/)

## Configuring AWS Credentials

```bash
aws configure
# Enter: Access Key ID, Secret Access Key, Region (us-east-1)
```

## Task 1 — Deploy the App to Kubernetes

The Docker image is published to DockerHub: `elonerajeev/devops-time-service:latest`

The app runs as a **non-root user** inside the container.

To deploy to a running Kubernetes cluster:

```bash
kubectl apply -f microservice.yml
```

To test locally:

```bash
kubectl port-forward svc/devops-time-service 8080:80
curl http://localhost:8080/
```

Expected response:
```json
{
  "timestamp": "2024-04-07T10:30:00.000Z",
  "ip": "127.0.0.1"
}
```

## Task 2 — Deploy Infrastructure with Terraform

### Step 1 — Create the remote backend (once only)

```bash
aws s3api create-bucket --bucket devops-bucket-state123654 --region us-east-1
aws s3api put-bucket-versioning --bucket devops-bucket-state123654 --versioning-configuration Status=Enabled
aws dynamodb create-table --table-name terraform-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST --region us-east-1
```

### Step 2 — Deploy VPC + EKS

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

**What gets created:**
- VPC with 2 public + 2 private subnets across 2 AZs
- EKS cluster with 2 × `m6a.large` nodes on private subnets
- NAT Gateway for private subnet egress

### Step 3 — Connect kubectl to the cluster

```bash
aws eks update-kubeconfig --region us-east-1 --name devops-time-service-eks
```

Then deploy the app with `kubectl apply -f microservice.yml`.

### Destroy infrastructure

```bash
cd terraform
terraform destroy
```

## CI/CD Pipeline (GitHub Actions)

On every push to `main`, the pipeline automatically:
1. Builds and pushes the Docker image to DockerHub (tagged with commit SHA)
2. Runs `terraform apply` to provision/update infrastructure
3. Updates the image tag in `microservice.yml` and runs `kubectl apply`

### Required GitHub Secrets

| Secret | Description |
|---|---|
| `DOCKERHUB_USERNAME` | Docker Hub username |
| `DOCKERHUB_TOKEN` | Docker Hub Personal Access Token |
| `AWS_ACCESS_KEY_ID` | AWS Access Key ID |
| `AWS_SECRET_ACCESS_KEY` | AWS Secret Access Key |
| `EKS_CLUSTER_NAME` | EKS cluster name |

## Security Notes

- App runs as a non-root user (`appuser`) inside the container
- EKS worker nodes are in private subnets only
- No secrets or credentials are committed to this repository
- Terraform state is encrypted and stored remotely in S3