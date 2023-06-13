
# provider "aws" {
#   region     = "us-east-1"
#   access_key = ""
#   secret_key = ""
# }

# # 1. Create vpc
# resource "aws_vpc" "tf-prod-vpc" {
#   cidr_block = "10.0.0.0/16"

#   tags = {
#     "Name" = "production"
#   }
# }

# 2. Create Internet Gateway
# resource "aws_internet_gateway" "tf-gateway" {
#   vpc_id = "vpc-0089edc3a7808c21d"

#   tags = {
#     Name = "main"
#   }
# }

# 3. Create Custom Route Table
resource "aws_route_table" "tf-prod-route-table" {
  vpc_id = "vpc-0089edc3a7808c21d"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "igw-02d12b71ae58cc3cb"
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = "igw-02d12b71ae58cc3cb"
  }

  tags = {
    Name = "prod"
  }
}

# 4. Create a Subnet 
resource "aws_subnet" "tf-subnet-1" {
  vpc_id            = "vpc-0089edc3a7808c21d"
  cidr_block        = "172.16.10.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "tf-subnet-for-ec2"
  }
}

# 5. Associate subnet with Route Table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.tf-subnet-1.id
  route_table_id = aws_route_table.tf-prod-route-table.id
}

# 6. Create Security Group to allow port 22,80,443
resource "aws_security_group" "tf-allow_web" {
  name        = "allow_web_traffic"
  description = "Allow TLS inbound traffic"
  vpc_id      = "vpc-0089edc3a7808c21d"

  ingress {
    description = "HTTPs traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_web"
  }
}

# 7. Create a network interface with an ip in the subnet that was created in step 4
resource "aws_network_interface" "tf-web-server-nic" {
  subnet_id       = aws_subnet.tf-subnet-1.id
  private_ips     = ["172.16.10.100"]
  security_groups = [aws_security_group.tf-allow_web.id]
}

# 8. Assign an elastic IP to the network interface created in step 7
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.tf-web-server-nic.id
  associate_with_private_ip = "172.16.10.100"
}

output "server_public_ip" {
  value = aws_eip.one.public_ip  
}

# 9. Create Ubuntu server and install/enable apache2
resource "aws_instance" "tf-web-server-instance-02" {
  ami               = "ami-04a0ae173da5807d3"
  instance_type     = "t2.micro"
  availability_zone = "us-east-1a"
  key_name          = "ec2-keypair"

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.tf-web-server-nic.id
  }

  user_data = <<-EOF
              #!/bin/bash
              # Use this for your user data (script from top to bottom)
              # install httpd (Linux 2 version)
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Hello World from $(hostname -f)</h1>" > /var/www/html/index.html
              EOF
  tags = {
    Name = "terraform web server"
  }
}
