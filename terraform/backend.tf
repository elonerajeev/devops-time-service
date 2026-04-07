terraform {
  backend "s3" {
    bucket         = "devops-bucket-state123654" 
    key            = "state/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}
