provider "aws" {
  region = "us-east-1"  # Update with your desired AWS region
}

# Define the VPC and subnet IDs of your existing VPC
variable "vpc_id" {
  default = "vpc-074a4b2e8189a4c4c"
}

variable "subnet_id" {
  default = "subnet-0b949409b339616e3"
}

# Create a security group to allow SSH access
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-instance-sg"
  description = "Security group for EC2 instance"

  vpc_id = var.vpc_id

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
  }
}

# Launch an EC2 instance
resource "aws_instance" "ec2_instance" {
  ami           = "ami-04a0ae173da5807d3"  # Replace with your desired AMI ID
  instance_type = "t2.micro"      # Replace with your desired instance type
  key_name      = "ec2-keypair" # Replace with your key pair name, if needed
  availability_zone = "us-east-1a"
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  subnet_id              = var.subnet_id
  associate_public_ip_address = true
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
}

output "public_ip" {
  value       = aws_instance.ec2_instance.public_ip
  description = "Public IP address of the EC2 instance"
}