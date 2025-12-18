variable "aws_source_ami" {
  default = "amzn2-ami-hvm-*-x86_64-gp2"
}
variable "aws_instance_type" {
  default = "t2.small"
}
variable "ami_name" {
  default = "ami-stack-14"
}
variable "component" {
  default = "clixx"
}
variable "aws_accounts" {
  type = list(string)
  default = ["529206289534"]
}
variable "ami_regions" {
  type = list(string)
  default =["us-east-1"]
}
variable "aws_region" {
  default = "us-east-1"
}
data "amazon-ami" "source_ami" {
  filters = {
    name = "${var.aws_source_ami}"
  }
  most_recent = true
  owners      = ["529206289534","amazon"]
  region      = "${var.aws_region}"
}
# locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }
# source blocks are generated from your builders; a source can be referenced in
# build blocks. A build block runs provisioners and post-processors on a
# source.
source "amazon-ebs" "amazon_ebs" {
  assume_role {
    role_arn     = "arn:aws:iam::529206289534:role/Engineer"
    session_name = "packer-ami-build"
  }
  ami_name                = "${var.ami_name}"
  ami_regions             = "${var.ami_regions}"
  ami_users               = "${var.aws_accounts}"
  snapshot_users          = "${var.aws_accounts}"
  encrypt_boot            = false
  instance_type           = "${var.aws_instance_type}"
  
  # VPC Configuration - critical for SSH connectivity
  vpc_id                  = "vpc-058151e894407c72e"
  subnet_id               = "subnet-0b5910db40ee70bc7"
  associate_public_ip_address = true
  
  launch_block_device_mappings {
    delete_on_termination = true
    device_name           = "/dev/xvda"
    encrypted             = false
    volume_size           = 10
    volume_type           = "gp2"
  }
  region                  = "${var.aws_region}"
  source_ami              = "${data.amazon-ami.source_ami.id}"
  ssh_pty                 = true
  ssh_timeout             = "10m"
  ssh_username            = "ec2-user"
}
# a build block invokes sources and runs provisioning steps on them.
build {
  sources = ["source.amazon-ebs.amazon_ebs"]
  provisioner "shell" {
    script = "../scripts/setup.sh"
  }
}
