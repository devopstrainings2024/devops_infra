terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
provider "aws" {
  profile = "devops"
  region  = "ap-south-1"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/20"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.0.0/21"  # First subnet
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.8.0/21"  # Second subnet
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "subnet_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "subnet_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "sg1" {
  vpc_id = aws_vpc.main.id
  name   = "sg1"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # Allows all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "sg2" {
  vpc_id = aws_vpc.main.id
  name   = "sg2"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # Allows all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ubuntu_server" {
  ami                    = "ami-0dee22c13ea7a9a67"  # Verify AMI ID
  instance_type          = "t2.medium"
  subnet_id              = aws_subnet.public_subnet_1.id
  vpc_security_group_ids  = [aws_security_group.sg1.id]

  root_block_device {
    volume_size           = 15  # Size in GB
    volume_type           = "gp2"  # General Purpose SSD
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update
              sudo apt install -y software-properties-common 
              sudo add-apt-repository --yes --update ppa:ansible/ansible
              sudo apt install -y ansible 
              sudo apt install -y tree
              EOF

  tags = {
    Name = "ConfigServer"
  }
}

resource "aws_instance" "ubuntu_server2" {
  ami                    = "ami-0dee22c13ea7a9a67"  # Verify AMI ID
  instance_type          = "t2.medium"
  subnet_id              = aws_subnet.public_subnet_2.id
  vpc_security_group_ids  = [aws_security_group.sg1.id]
  root_block_device {
    volume_size           = 15  # Size in GB
    volume_type           = "gp2"  # General Purpose SSD
  }

  user_data = <<-EOF
              #!/bin/bash
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCeCj/wftjo94yFablCDZplI/MtnHpnFocewjJ1CRmhW7m7zbHBHBC37oHpE1aWU8KPQF7Gb7sYZ86B5415Wv0iBHdVsMw3Q6l4T1VL4PvyOy+TZuNf0DcsuR7vQ9g0AhXBbB5yUZnD1QCuBRCbDwTqviFHq1A0uY2tLwpCWnWZazI61bTswQSox+rNi6X6m0pSmCZDwVRzis3N/oSbN3doj0lnvL4KtifInC0ox5leKei3EpNDfeUBPhU3dDQvF2tWqiyMq46Vt1FCZRKKJAUbAPeWRxlbHlKnQFuNYvyGYoPiQ7HnBEeOvOqn7sMy2txC8S2rIWzWoEC/9ZkLmHr+3J7LaemK5D92AKeG3RUGE4d4hV6obAvGvNIM7mWWnmTByFqVaogPkdNJGTwiFty0Ou3fJyKIhcsDIobZ0O+WSxBak9i+mQv1nkhQZq3f6Y+DoXka5OOphSX4ZVPOhL4lkhIttQUrNik01oKQ2wYR4nMGvN+TPdWnMPi1CKhmsO0= ubuntu@ip-10-0-0-30" >> /home/ubuntu/.ssh/authorized_keys
              EOF

  tags = {
    Name = "Servers"
  }
count=3
}
# Create an Elastic IP
resource "aws_eip" "web_eip" {
  instance = aws_instance.ubuntu_server.id  # Attach the Elastic IP to the instance
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_1_id" {
  value = aws_subnet.public_subnet_1.id
}

output "public_subnet_2_id" {
  value = aws_subnet.public_subnet_2.id
}

output "ubuntu_instance_id" {
  value = aws_instance.ubuntu_server.id
}

output "elastic_ip" {
  value = aws_eip.web_eip.public_ip  # Output the Elastic IP
}
