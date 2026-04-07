# SimpleTimeService - Particle41 DevOps Challenge

Welcome to the `SimpleTimeService` repository! This project aims to demonstrate a modern, Infrastructure-as-Code (IaC) approach to application deployment using AWS, Terraform, Docker, and Kubernetes (EKS).

## Project Overview

The repository consists of:
1. **SimpleTimeService App**: A minimalist Node.js web service that returns the current timestamp and the visitor's IP address as a JSON response.
2. **Infrastructure (Terraform)**: Modules to provision a secure, scalable AWS environment featuring a custom VPC (public/private subnets) and an EKS cluster.
3. **CI/CD Pipeline**: A GitHub Actions workflow that automatically:
   - Builds and pushes the Docker image to Docker Hub.
   - Deploys the application to the EKS cluster.

## Prerequisites

Before deploying, ensure you have the following tools installed:
- **AWS CLI**: [Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- **Terraform (v1.5.0+)**: [Installation Guide](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- **Kubectl**: [Installation Guide](https://kubernetes.io/docs/tasks/tools/)
- **Docker**: [Installation Guide](https://docs.docker.com/get-docker/)

## 1. Authentication

### Local Authentication
Run the following command and provide your Access Key, Secret Key, and default region (e.g., `us-east-1`):
```bash
aws configure
```

### GitHub Actions Secrets
To enable the CI/CD pipeline, add the following secrets to your GitHub repository:
- `DOCKERHUB_USERNAME`: Your Docker Hub username.
- `DOCKERHUB_TOKEN`: Your Docker Hub Personal Access Token (PAT).
- `AWS_ACCESS_KEY_ID`: Your AWS Access Key ID.
- `AWS_SECRET_ACCESS_KEY`: Your AWS Secret Access Key.

## 2. Infrastructure Deployment (Terraform)

The Terraform configuration uses a **remote S3 backend with DynamoDB locking** to maintain state. Ensure you have created the S3 bucket and DynamoDB table (configured in `terraform/backend.tf`) before starting.

1. Navigate to the terraform directory:
   ```bash
   cd terraform
   ```
2. Initialize and deploy:
   ```bash
   terraform init
   terraform apply
   ```

## 3. Continuous Deployment (CD)

Once your infrastructure is up, any push to the `main` branch will trigger the GitHub Actions workflow. This workflow will build a new Docker image, push it to Docker Hub, and then automatically update your EKS deployment using the `microservice.yml` manifest.

To manually deploy for the first time or check the status:
1. Update local `kubeconfig`:
   ```bash
   aws eks update-kubeconfig --region us-east-1 --name devops-time-servic-eks
   ```
2. Apply the manifest:
   ```bash
   kubectl apply -f microservice.yml
   ```

## Project Structure

- `web-app/`: Node.js application, `Dockerfile`, and `.dockerignore`.
- `terraform/`: IaC modules for VPC and EKS, and `backend.tf`.
- `.github/workflows/`: CI/CD pipeline definition.
- `microservice.yml`: The Kubernetes manifest for the application.

## Security Note
- No secrets or sensitive credentials are committed to this repository.
- The application runs as a non-root user within the container.
- EKS worker nodes are placed in private subnets with egress via NAT Gateway.
