# ========================================
# TLS Private Key
# ========================================
resource "tls_private_key" "ec2" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# ========================================
# AWS Key Pair
# ========================================
resource "aws_key_pair" "ec2" {
  key_name   = "${var.project_name}-keypair"
  public_key = tls_private_key.ec2.public_key_openssh

  tags = {
    Name = "${var.project_name}-keypair"
  }
}

# ========================================
# Save Private Key Locally
# ========================================
resource "local_file" "private_key" {
  content         = tls_private_key.ec2.private_key_pem
  filename        = "${path.module}/${var.project_name}-keypair.pem"
  file_permission = "0400"
}
