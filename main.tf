resource "aws_instance" "buildstack-ec2" {
     ami           = "${var.aws_ec2_ami}"
     instance_type = "${var.aws_ec2_instance_type}"
     key_name = "${var.aws_ec2_keyname}"
     security_groups = ["${aws_security_group.ingress-all-buildstack.id}"]
     subnet_id = "${aws_subnet.buildstack-subnet-main.id}"
     user_data = <<-EOF
        #!/bin/bash
        echo "Formatting and mounting EBS volumes"
        # Storage
        ## Make and format the docker filesystem, create target dir and mount it
        sudo mkfs -t xfs /dev/xvdc
        sudo mkdir -p /var/lib/docker
        sudo mount /dev/xvdc /var/lib/docker

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

        # OS settings for sonar
        ## Temporary (until reboot)
        sudo sysctl -w vm.max_map_count=262144
        sudo sysctl -w fs.file-max=65536
        sudo ulimit -n 65536
        sudo ulimit -u 4096
        ## Permanent
        sudo curl -L https://raw.githubusercontent.com/mikefinn/terraform-aws-buildstack/main/sonar/local/etc/sysctl.d/99-sonarqube.conf -o /etc/sysctl.d/99-sonarqube.conf
        sudo curl -L https://raw.githubusercontent.com/mikefinn/terraform-aws-buildstack/main/sonar/local/etc/security/limits.d/99-sonarqube.conf -o /etc/security/limits.d/99-sonarqube.conf

        ## Get the compose file for the stack
        mkdir /home/ec2-user/buildstack
        curl -L https://raw.githubusercontent.com/mikefinn/terraform-aws-buildstack/main/docker-compose.yml -o /home/ec2-user/buildstack/docker-compose.yml
        chown ec2-user:ec2-user /home/ec2-user/buildstack/docker-compose.yml

        # Make the mounts permanent
        ## Back up the fstab
        sudo cp /etc/fstab /etc/fstab.bak
        ## Append to fstab
        echo -e "UUID=`blkid /dev/xvdc | awk -F'"' '{print $2}'`\t/var/lib/docker\txfs\tdefaults\t1 2" | sudo tee -a /etc/fstab

        # OS updates
        sudo yum update -y         
    EOF

    tags = {
        Name = "buildstack-ec2"
    }

}

# for /var/lib/docker. Root FS does not provide enough space for docker storage.
resource "aws_ebs_volume" "buildstack-ec2-docker-vol" {
  availability_zone = "${var.aws_region_az}"
  size              = 50
  tags = {
    Name = "buildstack-ec2-docker-vol"
  }
}

resource "aws_volume_attachment" "buildstack-ec2-docker-vol" {
 device_name = "/dev/sdc"
 volume_id = "${aws_ebs_volume.buildstack-ec2-docker-vol.id}"
 instance_id = "${aws_instance.buildstack-ec2.id}"
}
