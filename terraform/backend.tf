terraform {
  backend "s3" {
    bucket = "terraform-s3-bucket-518808041266-us-east-1-an"
    key    = "terraform_lab5/terraform.tfstate"
    region = "us-east-1"
  }
}