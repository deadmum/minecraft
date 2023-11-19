terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
}


provider "aws" {
  profile = "default"
  region  = "eu-central-1"
}

resource "aws_security_group" "minecraft" {
  ingress {
    description = "Receive SSH from home."
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Receive Minecraft from everywhere."
    from_port   = 25565
    to_port     = 25565
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Send everywhere."
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Minecraft"
  }
}



resource "aws_instance" "minecraft" {
  ami                         = "ami-0669b163befffbdfc"
  instance_type               = "t2.small"
  vpc_security_group_ids      = [aws_security_group.minecraft.id]
  associate_public_ip_address = true
  user_data                   = <<-EOF
    #!/bin/bash
    sudo dnf -y update
    sudo dnf -y install docker


    sudo curl https://github.com/led0nk.keys >> /home/ec2-user/.ssh/authorized_keys
    sudo chown ec2-user: /home/ec2-user/.ssh/authorized_keys
    sudo chmod 600 /home/ec2-user/.ssh/authorized_keys
    sudo systemctl start docker.service
    sudo systemctl enable docker.service
    sudo docker run --rm -it -p 0.0.0.0:25565:25565 ghcr.io/led0nk/minecraft:latest

    EOF
  tags = {
    Name = "Minecraft"
  }
}

output instance_ip_addr {
  value = aws_instance.minecraft.public_ip
}

output instance_public_dns {
  value = aws_instance.minecraft.public_dns
}