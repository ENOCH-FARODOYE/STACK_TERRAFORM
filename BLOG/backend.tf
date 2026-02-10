terraform {
  backend "s3" {
    bucket         = "clixx-terraform-state-enoch"
    key            = "blog/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "clixx-terraform-locks"
  }
}
