terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
}

#variable "your_region" {
#  type        = string
#  description = "eu-central-1"
#}

#variable "your_ip" {
#  type        = string
#  description = "insert your IP e.g. $(curl ifconfig.me)"
#}

#variable "your_public_key" {
#  type        = string
#  description = "insert SSH Token"
#}

#variable "mojang_server_url" {
#  type        = string
#  description = "https://piston-data.mojang.com/v1/objects/5b868151bd02b41319f54c8d4061b8cae84e665c/server.jar"
#}

data "http""your_ip" {
  url = "http://ifconfig.me"
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
    cidr_blocks = ["${data.http.your_ip.body}/32"]
#    cidr_blocks = ["0.0.0.0/0"]
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

#resource "aws_key_pair" "home" {
#  key_name   = "Home"
#  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCoJXZkOgs6U0JvRQOUbxsqgYjHwlv4vqnzh8RyACnLq/p8nO8WzGlkNCbGJ9UkIpHkxPaKC8W/tctNIc42OC4jGgrHfJrM/pZC4M8QyRznZfiummTcRyUoLaJJMKoZxDc0hrIm19h12riYndyOsvIZFpCxJ9RRNDKi38zrYEtm1ZILpyyR8KX92+PP8Zxj7uHEL1k0ZFiErhKSI2Wk0D967o3yOlYExvZVDCSL8xth5H5rrcEmjJHmnAt2tWwIj7lV5Q0AfHD2cX3fRBerbtAvBWv7jhGFk6H7H4aol56VWl/9c4T4Fk9cTCCsmNPDiTvTGJ4gV9SX3LKaob82TLRTeEGdAjcDsyiNBxS+t3vgtMbwwExFfc6YYLMqEIydJhuf5W0gduxa8UwawItGMR0ykyPPmHstraM+R5HAFkKGiW0VEHDkpylQ4kfctVSMZyN4Ov0TXEpepQaGmdftIYxjKn2hX/7SD4UPzusVRW1ZjPYW5/hcOQ5Zi1wrrND2BDkDSPKl1qJ0Cydz7p5NjrFAopp2kKK6JsiGJ3MeF350pjSrUxYKH326ahzedtcf6jmz2KM6jieRPnX6cQimYnf/NaxQhzCR55J8LTw0La8BB8/2y7frESq7vz8carKewpjQKZbHt1b56R/9kAq8ixQ1ythIq0nJLOoQlJR8z5DMmw== janik.knodel@gmail.com"
#}

resource "aws_instance" "minecraft" {
  ami                         = "ami-0669b163befffbdfc"
  instance_type               = "t2.small"
  vpc_security_group_ids      = [aws_security_group.minecraft.id]
  associate_public_ip_address = true
#  key_name                    = aws_key_pair.home.key_name
  user_data                   = <<-EOF
    #!/bin/bash
    sudo dnf -y update
    sudo dnf -y install docker


    sudo curl https://github.com/led0nk.keys >> /home/ec2-user/.ssh/authorized_keys
    sudo chown ec2-user: /home/ec2-user/.ssh/authorized_keys
    sudo chmod 600 /home/ec2-user/.ssh/authorized_keys
    sudo systemctl start docker.service
    sudo systemctl enable docker.service
    sudo docker run --rm -it -p 0.0.0.0:25565:25565 ghcr.io/frzifus/minecraft:latest

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



#curl infconfig.me
