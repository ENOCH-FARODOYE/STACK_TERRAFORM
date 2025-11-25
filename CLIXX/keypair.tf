##############################################################################
# EC2 Key Pair
##############################################################################

# Generate private key
resource "tls_private_key" "main" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create AWS key pair from generated public key
resource "aws_key_pair" "main" {
  provider = aws.dev

  key_name   = "${var.project_name}-key"
  public_key = tls_private_key.main.public_key_openssh

  tags = {
    Name = "${var.project_name}-key"
  }
}

# Save private key to local file
resource "local_file" "private_key" {
  content         = tls_private_key.main.private_key_pem
  filename        = "${path.module}/clixx-key.pem"
  file_permission = "0400"
}
