# See https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html

resource "aws_vpc" "buildstack-vpc" {
  cidr_block = "${var.aws_vpc_cidr}"
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = {
    Name = "buildstack-vpc"
  }
}

# Subnet
resource "aws_subnet" "buildstack-subnet-main" {
  cidr_block = "${var.aws_subnet_cidr}"
  vpc_id = "${aws_vpc.buildstack-vpc.id}"
  availability_zone = "${var.aws_region_az}"
  tags = {
    Name = "buildstack-vpc"
  }
}

# Security Group
resource "aws_security_group" "ingress-all-buildstack" {
    name = "ingress-all-buildstack"
    vpc_id = "${aws_vpc.buildstack-vpc.id}"
    # SSH
    ingress {
        cidr_blocks = [ "${var.aws_sg_inbound_source_cidr}" ]
        from_port = 22
        to_port = 22
        protocol = "tcp"
        description = "Allow SSH inbound"
    }
    # HTTPD
    ingress {
        cidr_blocks = [ "${var.aws_sg_inbound_source_cidr}" ]
        from_port = 80
        to_port = 80
        protocol = "tcp"
        description = "Allow HTTPD inbound"
    }
    # Nexus
    ingress {
        cidr_blocks = [ "${var.aws_sg_inbound_source_cidr}" ]
        from_port = 8081
        to_port = 8081
        protocol = "tcp"
        description = "Allow Nexus"
    }
    # IQ Server
    ingress {
        cidr_blocks = [ "${var.aws_sg_inbound_source_cidr}" ]
        from_port = 8070
        to_port = 8070
        protocol = "tcp"
        description = "Allow Nexus IQ Server"
    }
    # Tomcat (test env)
    ingress {
        cidr_blocks = [ "${var.aws_sg_inbound_source_cidr}" ]
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        description = "Allow Tomcat"
    }
    # Jenkins
    ingress {
        cidr_blocks = [ "${var.aws_sg_inbound_source_cidr}" ]
        from_port = 8082
        to_port = 8082
        protocol = "tcp"
        description = "Allow Tomcat"
    }
// Terraform removes the default rule
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
      Name = "buildstack-sg"
    }

}

# IGW
resource "aws_internet_gateway" "buildstack-igw" {

  vpc_id = "${aws_vpc.buildstack-vpc.id}"
  tags = {
      Name = "buildstack-igw"
    }
}

# Subnets
resource "aws_route_table" "route-table-buildstack" {
  vpc_id = "${aws_vpc.buildstack-vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.buildstack-igw.id}"
  }
  tags = {
      Name = "buildstack-route-table"
  }
}
resource "aws_route_table_association" "subnet-association" {
  subnet_id      = "${aws_subnet.buildstack-subnet-main.id}"
  route_table_id = "${aws_route_table.route-table-buildstack.id}"
}

# Elastic IP for EC2 instance
# HACK: Need to put the remote-exec stuff here so TF provisioner can find the 
#   EIP public IP to connect to. This is the only way it seems to work.
# See: https://github.com/hashicorp/terraform/issues/6394. 
resource "aws_eip" "buildstack-eip" {
    instance = "${aws_instance.buildstack-ec2.id}"
    vpc      = true

    connection {
        type        =  "ssh"
        #host        =  self.public_ip
        host        = "${self.public_ip}"
        user        = "ec2-user"
        private_key = file("~/ssh-keys/tf-poc.pem")
    }
    # If you need to copy a file from terraform runner to new ec2, uncomment and edit
    #provisioner "file" {
    #  source  ="sourcefile"
    #  destination = "targetfile"
    #}
    tags = {
      Name = "buildstack-eip"
    }
}