provider "aws" {
  region     = var.AWS_REGION
  access_key = var.AWS_ACCESS_KEY
  secret_key = var.AWS_SECRET_KEY
}

# Second provider for cross-account replication (different account, same region us-east-1)
provider "aws" {
  alias      = "destination_account"
  region     = var.replication_region
  access_key = var.DEST_AWS_ACCESS_KEY
  secret_key = var.DEST_AWS_SECRET_KEY
}

# Third provider for cross-region replication (same account, different region us-west-1)
provider "aws" {
  alias      = "cross_region"
  region     = var.cross_region
  access_key = var.AWS_ACCESS_KEY
  secret_key = var.AWS_SECRET_KEY
}
