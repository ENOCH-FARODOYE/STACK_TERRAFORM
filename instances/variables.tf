# variable "cidr_vpc" {
#   description = "CIDR block for the VPC"
#   default     = "10.1.0.0/16"
# }
# variable "cidr_subnet" {
#   description = "CIDR block for the subnet"
#   default     = "10.1.0.0/24"
# }
variable "environment_tag" {
  description = "Environment tag"
  default     = "Learn"
}
variable "region"{
  description = "The region Terraform deploys your instance"
  default     = "us-east-1"
}
variable "vpc_id"{
    default="vpc-058151e894407c72e"
}
variable "subnets" {
  type = list(string)
  default=[
    "subnet-0b5910db40ee70bc7",
    "subnet-091e3f27d8a7e62f7",
   ]
}
variable "PATH_TO_PUBLIC_KEY" {
  default = "ses_key.pub"
}
variable "ami_name" {
  default = "ami-stack-14"
}
