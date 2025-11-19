# Cross-Account Provider: Management (978820380225) → Dev (529206289534)
provider "aws" {
  region  = "us-east-1"
  profile = "stack_enoch_admin"

  assume_role {
    role_arn = "arn:aws:iam::529206289534:role/Engineer"
  }
}
