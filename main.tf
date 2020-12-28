resource "aws_instance" "mjf-buildstack-poc-ec2" {
     ami           = "${var.aws_ec2_ami}"
     instance_type = "${var.aws_ec2_instance_type}"
     key_name = "${var.aws_ec2_keyname}"
     security_groups = ["${aws_security_group.ingress-all-mjf-buildstack-poc.id}"]
     subnet_id = "${aws_subnet.mjf-buildstack-poc-subnet-main.id}"
     user_data = <<-EOF
        #!/bin/bash
        echo "Formatting and mounting EBS volumes"
        # Storage
        ## Make and format the data filesystem, create target dir and mount it
        sudo mkfs -t xfs /dev/xvdc
        sudo mkdir /opt
        sudo mount /dev/xvdc /opt
        ## Make and format the docker filesystem, create target dir and mount it
        sudo mkfs -t xfs /dev/xvdf
        sudo mkdir -p /var/lib/docker
        sudo mount /dev/xvdf /var/lib/docker

        # Make the mounts permanent
        ## Back up the fstab
        sudo cp /etc/fstab /etc/fstab.bak
        ## Append to fstab
        echo -e "UUID=`blkid /dev/xvdc | awk -F'"' '{print $2}'`\t/opt\txfs\tdefaults\t1 2" | sudo tee -a /etc/fstab
        echo -e "UUID=`blkid /dev/xvdf | awk -F'"' '{print $2}'`\t/var/lib/docker\txfs\tdefaults\t1 2" | sudo tee -a /etc/fstab

        # Docker/Docker Compose
        ## Install docker and start
        sudo amazon-linux-extras install docker
        sudo service docker start
        ## Set up ec2-user to run docker
        sudo usermod -a -G docker ec2-user   
        ## Enable docker to start w system
        sudo chkconfig docker on    
        ## Install Docker Compose
        sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose

        # OS updates
        sudo yum update -y         
    EOF

    tags = {
        Name = "mjf-buildstack-poc-ec2"
    }

}

# for /opt
resource "aws_ebs_volume" "mjf-buildstack-poc-ec2-data-vol" {
  availability_zone = "${var.aws_region_az}"
  size              = 50
  tags = {
    Name = "mjf-buildstack-poc-ec2-data-vol"
  }
}

# for /var/lib/docker. Root FS does not provide enough space for docker storage.
resource "aws_ebs_volume" "mjf-buildstack-poc-ec2-docker-vol" {
  availability_zone = "${var.aws_region_az}"
  size              = 50
  tags = {
    Name = "mjf-buildstack-poc-ec2-docker-vol"
  }
}

resource "aws_volume_attachment" "mjf-buildstack-poc-ec2-data-vol" {
 device_name = "/dev/sdc"
 volume_id = "${aws_ebs_volume.mjf-buildstack-poc-ec2-data-vol.id}"
 instance_id = "${aws_instance.mjf-buildstack-poc-ec2.id}"
}

resource "aws_volume_attachment" "mjf-buildstack-poc-ec2-docker-vol" {
 device_name = "/dev/sdf"
 volume_id = "${aws_ebs_volume.mjf-buildstack-poc-ec2-docker-vol.id}"
 instance_id = "${aws_instance.mjf-buildstack-poc-ec2.id}"
}
