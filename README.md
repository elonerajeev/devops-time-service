#  SimpleTimeService — Particle41 DevOps Challenge

A production-grade, cloud-native microservice that returns the current timestamp and visitor IP — deployed on AWS EKS using Terraform, Docker, Kubernetes, and GitHub Actions CI/CD.

---

## 📁 Repository Structure

```
devops-time-service/
├── web-app/                    # Node.js application
│   ├── server.js               # Main app — returns timestamp + IP
│   ├── Dockerfile              # Multi-stage, non-root container
│   ├── package.json
│   └── .dockerignore
├── terraform/                  # Infrastructure as Code (IaC)
│   ├── main.tf                 # Root module — calls VPC + EKS modules
│   ├── variables.tf            # All input variable definitions
│   ├── terraform.tfvars        # Default variable values
│   ├── outputs.tf              # Cluster + VPC output values
│   ├── backend.tf              # Remote S3 + DynamoDB state backend
│   └── modules/
│       ├── vpc/                # Custom VPC module (subnets, NAT, routes)
│       └── eks/                # EKS cluster + managed node group
├── .github/workflows/
│   └── deploy.yml              # GitHub Actions CI/CD pipeline
├── microservice.yml            # Kubernetes Deployment + Service manifest
└── README.md
```

---

## 🌐 What Does the App Do?

The `SimpleTimeService` is a tiny Node.js web server. Hit its `/` endpoint and it responds with:

```json
{
  "timestamp": "2024-04-07T10:30:00.000Z",
  "ip": "103.21.244.5"
}
```

That's it. Simple, fast, and stateless.

---

## 🏗️ Architecture Overview

```
                        ┌─────────────────────────────────┐
                        │           AWS Region             │
                        │                                  │
                        │   ┌──────────────────────────┐  │
                        │   │          VPC              │  │
                        │   │   CIDR: 10.0.0.0/16      │  │
                        │   │                          │  │
                        │   │  ┌──────┐  ┌──────┐    │  │
                        │   │  │Pub-0 │  │Pub-1 │    │  │
                        │   │  │ AZ-a │  │ AZ-b │    │  │
                        │   │  └──┬───┘  └──────┘    │  │
                        │   │     │ NAT GW             │  │
                        │   │  ┌──┴───┐  ┌──────┐    │  │
                        │   │  │Pri-0 │  │Pri-1 │    │  │
                        │   │  │EKS   │  │ EKS  │    │  │
                        │   │  │Node  │  │ Node │    │  │
                        │   │  └──────┘  └──────┘    │  │
                        │   └──────────────────────────┘  │
                        └─────────────────────────────────┘

GitHub push → GitHub Actions CI/CD
  1. Build & push Docker image to DockerHub
  2. Terraform apply (VPC + EKS)
  3. kubectl apply -f microservice.yml → EKS
```

**Key security decisions:**
- EKS worker nodes live in **private subnets only**
- Private subnets reach the internet through a **NAT Gateway** (for pulling images etc.)
- The Kubernetes Service is **ClusterIP** (not exposed to the internet directly — access via `kubectl port-forward` or an Ingress)
- The container runs as a **non-root user** (`appuser`)

---

##  Requirements Checklist

| Requirement | Status | Details |
|---|---|---|
| Web service returns `{ timestamp, ip }` at `/` | ✅ | `web-app/server.js` |
| Runs as non-root user in container | ✅ | `appuser` in `Dockerfile` |
| Docker image published to DockerHub | ✅ | `elonerajeev/devops-time-service` |
| K8s manifest with Deployment + Service | ✅ | `microservice.yml` |
| Service type is NOT LoadBalancer | ✅ | `ClusterIP` |
| `kubectl apply -f microservice.yml` is the only deploy command | ✅ | |
| Pod resource requests + limits | ✅ | CPU 100m/200m, Memory 128Mi/256Mi |
| Terraform VPC: 2 public + 2 private subnets | ✅ | `modules/vpc` |
| EKS: 2 nodes, `m6a.large`, private subnets only | ✅ | `modules/eks` |
| No secrets committed to repo | ✅ | All secrets via GitHub Actions Secrets |
| Remote Terraform backend (S3 + DynamoDB) | ✅ | `backend.tf` *(Extra Credit)* |
| CI/CD pipeline | ✅ | `.github/workflows/deploy.yml` *(Extra Credit)* |
| README with full deployment instructions | ✅ | This file |

---

## 🛠️ Prerequisites

Install these tools before you start:

| Tool | Version | Install |
|---|---|---|
| AWS CLI | v2+ | [aws.amazon.com/cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) |
| Terraform | v1.5.0+ | [terraform.io](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) |
| kubectl | v1.28+ | [kubernetes.io](https://kubernetes.io/docs/tasks/tools/) |
| Docker | Latest | [docker.com](https://docs.docker.com/get-docker/) |
| Git | Any | [git-scm.com](https://git-scm.com/downloads) |

---

## 🔐 Step 0 — Configure AWS Credentials

**Option A — Local development (recommended for testing):**
```bash
aws configure
# Enter your: AWS Access Key ID, Secret Access Key, Region (us-east-1), Output format (json)
```

>  **Never commit credentials to git.** Use IAM roles or environment variables only.

---

## 🏗️ Step 1 — Bootstrap the Terraform Backend

The Terraform state is stored remotely in S3 with DynamoDB locking. You need to create these **once**, before running `terraform init`.

```bash
# Create the S3 bucket (replace with your own unique bucket name)
aws s3api create-bucket \
  --bucket devops-bucket-state123654 \
  --region us-east-1

# Enable versioning on the bucket (important for state recovery)
aws s3api put-bucket-versioning \
  --bucket devops-bucket-state123654 \
  --versioning-configuration Status=Enabled

# Create the DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

> 💡 These values must match exactly what's in `terraform/backend.tf`. If you use different names, update `backend.tf` accordingly.

---

## ☁️ Step 2 — Deploy Infrastructure with Terraform

```bash
# Navigate to the terraform directory
cd terraform

# Download required providers and configure the S3 backend
terraform init

# Preview what resources will be created (no changes made yet)
terraform plan

# Create the VPC and EKS cluster (~10-15 minutes)
terraform apply
```

**What gets created:**
- 1 VPC (`10.0.0.0/16`)
- 2 Public subnets (`10.0.101.0/24`, `10.0.102.0/24`) across 2 AZs
- 2 Private subnets (`10.0.1.0/24`, `10.0.2.0/24`) across 2 AZs
- 1 Internet Gateway
- 1 NAT Gateway (shared, in public subnet)
- 1 EKS cluster (`devops-time-service-eks`, Kubernetes 1.29)
- 1 Managed Node Group: 2× `m6a.large` in private subnets

---

## 🐳 Step 3 — Deploy the App to Kubernetes

Once the EKS cluster is up, configure `kubectl` to talk to it:

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name devops-time-service-eks
```

Then deploy the microservice:

```bash
# From the root of the repo
kubectl apply -f microservice.yml
```

Verify it's running:

```bash
kubectl get pods
kubectl get svc
```

Expected output:
```
NAME                                    READY   STATUS    RESTARTS   AGE
devops-time-service-xxxxx-yyyy          1/1     Running   0          30s
devops-time-service-xxxxx-zzzz          1/1     Running   0          30s

NAME                  TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
devops-time-service   ClusterIP   172.20.x.x      <none>        80/TCP    30s
```

Test the endpoint locally via port-forward:

```bash
kubectl port-forward svc/devops-time-service 8080:80
curl http://localhost:8080/
```

Expected response:
```json
{
  "timestamp": "2024-04-07T10:30:00.000Z",
  "ip": "::ffff:127.0.0.1"
}
```

---

## 🐋 Working with Docker (Optional)

Build and run the image locally to test before deploying:

```bash
# Build the image
docker build -t devops-time-service ./web-app

# Run it locally
docker run -p 3000:3000 devops-time-service

# Test it
curl http://localhost:3000/
```

Pull the published image from DockerHub:

```bash
docker pull elonerajeev/devops-time-service:latest
```

---

## ⚙️ Step 4 — CI/CD with GitHub Actions (Automatic Deployment)

The `.github/workflows/deploy.yml` pipeline runs automatically on every push to `main`. It does three things in sequence:

```
Push to main
     │
     ▼
┌─────────────┐     ┌───────────────────┐
│ build-and-  │     │  infrastructure   │
│   push      │     │ (terraform apply) │
│             │     │                   │
│ Build image │     │ Provisions VPC +  │
│ Push to Hub │     │ EKS if not exists │
└──────┬──────┘     └────────┬──────────┘
       │                     │
       └──────────┬──────────┘
                  ▼
          ┌───────────────┐
          │    deploy     │
          │               │
          │ Update image  │
          │ in manifest   │
          │ kubectl apply │
          └───────────────┘
```

### Required GitHub Secrets

Go to your repo → **Settings → Secrets and variables → Actions → New repository secret** and add:

| Secret Name | Description |
|---|---|
| `DOCKERHUB_USERNAME` | Your Docker Hub username |
| `DOCKERHUB_TOKEN` | Docker Hub Personal Access Token (PAT) |
| `AWS_ACCESS_KEY_ID` | AWS IAM user Access Key ID |
| `AWS_SECRET_ACCESS_KEY` | AWS IAM user Secret Access Key |
| `EKS_CLUSTER_NAME` | Your EKS cluster name (e.g., `devops-time-service-eks`) |

> 💡 To create a Docker Hub PAT: DockerHub → Account Settings → Security → New Access Token

---

## 🔧 Customising Variables

All infrastructure settings are in `terraform/terraform.tfvars`. You can change them without editing any module code:

```hcl
# terraform/terraform.tfvars

region             = "us-east-1"          # AWS region
cluster_name       = "devops-time-service-eks"
kubernetes_version = "1.29"
vpc_cidr           = "10.0.0.0/16"

availability_zones   = ["us-east-1a", "us-east-1b"]
private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24"]

node_instance_types = ["m6a.large"]       # EC2 instance type for worker nodes
node_desired_size   = 2                   # Number of nodes to run
node_min_size       = 2
node_max_size       = 2

single_nat_gateway = true                 # Use 1 NAT GW (cheaper) vs one per AZ
```

---

## 💥 Teardown (Destroy Everything)

> ⚠️ This will **permanently delete** all AWS resources and will stop incurring costs.

```bash
cd terraform
terraform destroy
```

To also delete the backend resources (do this last):
```bash
# Empty the S3 bucket first (required before deletion)
aws s3 rm s3://devops-bucket-state123654 --recursive
aws s3api delete-bucket --bucket devops-bucket-state123654 --region us-east-1

# Delete DynamoDB lock table
aws dynamodb delete-table --table-name terraform-lock --region us-east-1
```

---

## 🔒 Security Highlights

- **Non-root container**: The app runs as `appuser` (not root) inside Docker
- **Private worker nodes**: EKS nodes are placed in private subnets — no direct internet exposure
- **NAT Gateway egress**: Private nodes can pull images and updates outbound, but are not reachable inbound
- **ClusterIP service**: The app is not exposed to the public internet via the Service; access is internal or via `port-forward`
- **No secrets in code**: All credentials are injected at runtime via GitHub Actions Secrets or `aws configure`
- **State encryption**: Terraform state is encrypted at rest in S3 (`encrypt = true` in `backend.tf`)

---

## 🐛 Troubleshooting

**Pods stuck in `Pending`:**
```bash
kubectl describe pod <pod-name>
# Look at Events section — usually a node resource or image pull issue
```

**Terraform backend error (`NoSuchBucket`):**
> The S3 bucket in `backend.tf` doesn't exist yet. Go back to Step 1 and create it first.

**`kubectl` not connecting to cluster:**
```bash
# Re-run kubeconfig update
aws eks update-kubeconfig --region us-east-1 --name devops-time-service-eks

# Verify you're on the right context
kubectl config current-context
```

**Docker build fails locally:**
```bash
# Make sure Docker Desktop is running, then:
docker build --no-cache -t devops-time-service ./web-app
```

---

## 📌 Key Design Decisions

| Decision | Reason |
|---|---|
| Node.js + Express | Minimal footprint, fast startup, ideal for a stateless API |
| Multi-stage Dockerfile | Keeps the final image small (only production deps, no build tools) |
| `node:20-alpine` base | Smallest secure Node.js image available |
| ClusterIP (not LoadBalancer) | Cost-effective; LoadBalancer would spin up an AWS ELB per service |
| 2 replicas | High availability — one pod failure doesn't take the service down |
| Single NAT Gateway | Saves cost (`single_nat_gateway = true`) — acceptable for dev/staging |
| S3 + DynamoDB backend | Safe remote state with locking; no local `.tfstate` files in git |

---

## 👤 Author

**Rajeev Kumar (Elone)**  
DevOps/Cloud Engineer  
GitHub: [@elonerajeev](https://github.com/elonerajeev)  
DockerHub: [elonerajeev/devops-time-service](https://hub.docker.com/r/elonerajeev/devops-time-service)