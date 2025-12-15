terraform {
  backend "s3" {
    bucket         = "clixx-terraform-state-enoch"
    key            = "clixx/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "clixx-terraform-locks"
    
    # Assume Management account role to access S3 and DynamoDB
    role_arn       = "arn:aws:iam::978820380225:role/ClixxSSMParameterAccessRole"
  }
}
