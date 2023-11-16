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

variable "your_ip" {
  type        = string
  description = "insert your IP e.g. https://www.whatsmyip.org/"
}

#variable "your_public_key" {
#  type        = string
#  description = "insert SSH Token"
#}

variable "mojang_server_url" {
  type        = string
  description = "https://piston-data.mojang.com/v1/objects/5b868151bd02b41319f54c8d4061b8cae84e665c/server.jar"
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
    cidr_blocks = ["${var.your_ip}/32"]
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

resource "aws_key_pair" "home" {
  key_name   = "Home"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCoJXZkOgs6U0JvRQOUbxsqgYjHwlv4vqnzh8RyACnLq/p8nO8WzGlkNCbGJ9UkIpHkxPaKC8W/tctNIc42OC4jGgrHfJrM/pZC4M8QyRznZfiummTcRyUoLaJJMKoZxDc0hrIm19h12riYndyOsvIZFpCxJ9RRNDKi38zrYEtm1ZILpyyR8KX92+PP8Zxj7uHEL1k0ZFiErhKSI2Wk0D967o3yOlYExvZVDCSL8xth5H5rrcEmjJHmnAt2tWwIj7lV5Q0AfHD2cX3fRBerbtAvBWv7jhGFk6H7H4aol56VWl/9c4T4Fk9cTCCsmNPDiTvTGJ4gV9SX3LKaob82TLRTeEGdAjcDsyiNBxS+t3vgtMbwwExFfc6YYLMqEIydJhuf5W0gduxa8UwawItGMR0ykyPPmHstraM+R5HAFkKGiW0VEHDkpylQ4kfctVSMZyN4Ov0TXEpepQaGmdftIYxjKn2hX/7SD4UPzusVRW1ZjPYW5/hcOQ5Zi1wrrND2BDkDSPKl1qJ0Cydz7p5NjrFAopp2kKK6JsiGJ3MeF350pjSrUxYKH326ahzedtcf6jmz2KM6jieRPnX6cQimYnf/NaxQhzCR55J8LTw0La8BB8/2y7frESq7vz8carKewpjQKZbHt1b56R/9kAq8ixQ1ythIq0nJLOoQlJR8z5DMmw== janik.knodel@gmail.com"
}

resource "aws_instance" "minecraft" {
  ami                         = "ami-0669b163befffbdfc"
  instance_type               = "t2.small"
  vpc_security_group_ids      = [aws_security_group.minecraft.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.home.key_name
  user_data                   = <<-EOF
    #!/bin/bash
    sudo yum -y update
    sudo rpm --import https://yum.corretto.aws/corretto.key
    sudo curl -L -o /etc/yum.repos.d/corretto.repo https://yum.corretto.aws/corretto.repo
    sudo yum install -y java-17-amazon-corretto-devel.x86_64
    wget -O server.jar ${var.mojang_server_url}
    java -Xmx1024M -Xms1024M -jar server.jar nogui
    sed -i 's/eula=false/eula=true/' eula.txt
    java -Xmx1024M -Xms1024M -jar server.jar nogui
    EOF
  tags = {
    Name = "Minecraft"
  }
}

output "instance_ip_addr" {
  value = aws_instance.minecraft.public_ip
}
