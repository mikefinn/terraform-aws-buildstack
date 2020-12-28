variable "aws_profile" {
    default = "terraform"
    description = "Name of AWS profile. Usually found in $HOME/.aws/credentials. Created in IAM and must have sufficient perms to create all resources."
}

variable "aws_region" {
    default = "us-east-2"
    description = "AWS region in which to create resources"
}

variable "aws_region_az" {
    default = "us-east-2a"
    description = "AWS AZ"
}

# Red Hat Enterprise Linux 8 (HVM), SSD Volume Type
# ami-03d64741867e7bb94

# Fedora-Cloud-Base-32-1.5.x86_64-hvm-us-east-2-gp2-0
# ami-07be3f7c1c4f505ab
variable "aws_ec2_ami" {
    # Amazon Linux 2 AMI (HVM), SSD Volume Type
    default = "ami-0a0ad6b70e61be944"
    description = "AMI with which to create EC2 instance"
}

variable "aws_ec2_user" {
    default = "fedora"
    description = "Default user. Determined by AMI."
}

variable "aws_ec2_instance_type" {
    default = "t2.medium"
    description = "AWS instance type"
}

variable "aws_ec2_keyname" {
    default = "tf-poc"
    description = "SSH keypair name with which to access host."
}

variable "aws_vpc_cidr" {
    default = "10.0.0.0/16"
    description = "Address space for VPC"
}

variable "aws_subnet_cidr" {
    default = "10.0.0.0/24"
    description = "Address space for subnet"
}

variable "aws_sg_inbound_source_cidr" {
    default = "74.67.128.21/32"
    description = "Source IP allowed for inbound connections in Security group rules"
}