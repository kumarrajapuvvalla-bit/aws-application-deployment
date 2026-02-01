terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# ECR repository for storing the application image
resource "aws_ecr_repository" "app" {
  name                 = "aws-app-deployment-demo"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

# Security group allowing HTTP traffic
resource "aws_security_group" "web" {
  name        = "app-web-sg"
  description = "Allow inbound HTTP and SSH traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "app-web-sg"
  }
}

# Launch an EC2 instance to run the container
resource "aws_instance" "web" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type              = "t3.micro"
  subnet_id                  = data.aws_subnet_ids.default.ids[0]
  vpc_security_group_ids     = [aws_security_group.web.id]
  associate_public_ip_address = true
  key_name                   = var.key_name

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install docker -y
              service docker start
              usermod -a -G docker ec2-user
              docker login -u AWS -p $(aws ecr get-login-password --region ${var.region}) ${aws_ecr_repository.app.repository_url}
              docker pull ${aws_ecr_repository.app.repository_url}:latest
              docker run -d -p 80:3000 --name app ${aws_ecr_repository.app.repository_url}:latest
              EOF

  tags = {
    Name = "app-server"
  }
}

# Data sources for existing resources
data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}

output "ec2_public_ip" {
  value = aws_instance.web.public_ip
}
