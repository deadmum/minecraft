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
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
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

variable "aws_access_key" {
  type = string
  default = "null"
}

variable "aws_secret_key" {
  type = string
  default = "null"
}


#    sudo echo var.AWS_ACCESS_KEY_ID:var.AWS_SECRET_ACCESS_KEY > ~/.passwd-s3fs
#    sudo chmod 600 ~/.passwd-s3fs
#     -o passwd_file=~/.passwd-s3fs

resource "aws_instance" "minecraft" {
  ami                         = "ami-0b2a401a8b3f4edd3" #Fedora
# ami                         = "ami-0669b163befffbdfc" #Amazon Linux
  instance_type               = "t2.small"
  vpc_security_group_ids      = [aws_security_group.minecraft.id]
  associate_public_ip_address = true

  user_data                   = <<-EOF
    #!/bin/bash
    sudo dnf -y update
    sudo dnf -y install podman
    sudo dnf -y install s3fs-fuse

    sudo curl https://github.com/led0nk.keys >> /home/fedora/.ssh/authorized_keys
    sudo chown fedora: /home/fedora/.ssh/authorized_keys
    sudo chmod 600 /home/fedora/.ssh/authorized_keys

    sudo mkdir /mnt/tmp/
    sudo mkdir /mnt/tmp/world


    sudo s3fs minecraftbuck /mnt/tmp 

    sudo systemctl start podman.service
    sudo systemctl enable podman.service
    sudo podman run --rm -it -d -p 0.0.0.0:25565:25565 \
    -v /mnt/tmp/world:/minecraft/world:rshared \
    ghcr.io/led0nk/minecraft:latest

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