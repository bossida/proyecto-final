terraform {
  required_version = ">= 1.0"
   
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}
 
provider "aws" {
  region = var.aws_region
   
  default_tags {
    tags = {
      Proyecto = "TP-Final"
      Ambiente = var.environment
      Creado_Por = "Terraform"
    }
  }
}
 
# Crear una VPC
resource "aws_vpc" "vpc_tp_final" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
   
  tags = {
    Name = "pc-tp-final"
  }
}
 
# Crear una subnet pública
resource "aws_subnet" "pp6_public_subnet" {
  vpc_id = aws_vpc.vpc_tp_final.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"
  map_public_ip_on_launch = true
   
  tags = {
    Name = "pp6-subnet-publica"
  }
}
 
# Crear un Internet Gateway
resource "aws_internet_gateway" "pp6_igw" {
  vpc_id = aws_vpc.vpc_tp_final.id
   
  tags = {
    Name = "pp6-internet-gateway"
  }
}
 
# Crear una tabla de ruteo
resource "aws_route_table" "pp6_public_rt" {
  vpc_id = aws_vpc.vpc_tp_final.id
   
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.pp6_igw.id
  }
   
  tags = {
    Name = "pp6-tabla-ruteo-publica"
  }
}
 
# Asociar la subnet con la tabla de ruteo
resource "aws_route_table_association" "pp6_public_rta" {
  subnet_id = aws_subnet.pp6_public_subnet.id
  route_table_id = aws_route_table.pp6_public_rt.id
}
 
# Grupo de seguridad
resource "aws_security_group" "pp6_app_sg" {
  name_prefix = "app-tp-final"
  description = "Grupo de seguridad para tp final"
  vpc_id = aws_vpc.vpc_tp_final.id
   
  ingress {
    description = "Acceso SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
   
  ingress {
    description = "Aplicacion Web Python"
    from_port = 3000
    to_port = 3000
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
   
  egress {
    description = "Todo el trafico saliente"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
   
  tags = {
    Name = "grupo-seguridad-tp-final"
  }
}
 
# Generar clave SSH automáticamente
resource "tls_private_key" "pp6_key_pair" {
  algorithm = "RSA"
  rsa_bits = 2048
}
 
resource "aws_key_pair" "pp6_key" {
  key_name = "pp6-clave-ssh"
  public_key = tls_private_key.pp6_key_pair.public_key_openssh
   
  tags = {
    Name = "pp6-clave-ssh"
  }
}
 
# Instancia EC2
resource "aws_instance" "pp6_app" {
  ami = var.ami_id
  instance_type = var.instance_type
  key_name = aws_key_pair.pp6_key.key_name
  vpc_security_group_ids = [aws_security_group.pp6_app_sg.id]
  subnet_id = aws_subnet.pp6_public_subnet.id
  associate_public_ip_address = true
   
   
  tags = {
    Name = "pp6-instancia-iac"
    Tipo = "Servidor-Aplicacion"
  }
}

