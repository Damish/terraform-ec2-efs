
# resource "aws_default_subnet" "tf-subnet-default" {
#   vpc_id            = "vpc-074a4b2e8189a4c4c"
#   # cidr_block        = "172.16.10.0/24"
#   # availability_zone = "us-east-1a"

#   tags = {
#     Name = "tf-subnet-for-ec2"
#   }
# }

resource "aws_security_group" "tf-allow_web" {
  name        = "allow_web_traffic"
  description = "Allow TLS inbound traffic"
  vpc_id      = "vpc-074a4b2e8189a4c4c"
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

resource "aws_instance" "tf-web-server-instance-02" {
  ami               = "ami-04a0ae173da5807d3"
  instance_type     = "t2.micro"
  availability_zone = "us-east-1a"
  key_name          = "ec2-keypair"
  subnet_id = "subnet-0b949409b339616e3"
  vpc_security_group_ids = [aws_security_group.tf-allow_web.id]
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
  tags = {
    Name = "terraform web server"
  }
}
