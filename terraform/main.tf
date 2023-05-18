terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "eu-central-1"
}

resource "tls_private_key" "key_data" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "local_key_pair" {
  filename        = "terraform-key-pair.pem"
  file_permission = "0600"
  content         = tls_private_key.key_data.private_key_pem
}

resource "aws_key_pair" "terraform-key-pair" {
  key_name   = "terraform-key-pair"
  public_key = tls_private_key.key_data.public_key_openssh
}

resource "aws_security_group" "website_security_group" {
  name        = "website_security_group"
  description = "Allow inbound traffic on port 80 and SSH access on port 22"

  ingress {
    description = "Allow inbound traffic on port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow inbound traffic on port 22"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["91.235.225.206/32"]
  }


  egress {
    description = "Allow outbound traffic on all ports"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_instance" "app_server" {
  ami                    = "ami-04e601abe3e1a910f"
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.terraform-key-pair.key_name
  vpc_security_group_ids = [aws_security_group.website_security_group.id]

  user_data = file("user_data.sh")

  tags = {
    Name = "Terraform Instance"
  }

}