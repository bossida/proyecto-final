variable "aws_region" {
	description = "Región de AWS donde se van a crear todos los recursos"
	type = string
	default = "us-east-1"
} 

variable "environment" {
	description = "Ambiente de trabajo"
	type = string
	default = "laboratorio"
} 

variable "instance_type" {
	description = "Tipo de instancia EC2"
	type = string
	default = "t2.micro"
}

variable "ami_id" {
	description = "ID de la imagen Ubuntu 22.04"
	type = string
	default = "ami-0866a3c8686eaeeba"
}