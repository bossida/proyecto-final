output "ip_publica_instancia" {
	description = "IP pública de la instancia EC2"
	value = aws_instance.pp6_app.public_ip
} 

output "url_aplicacion" {
	description = "URL completa para acceder a la aplicación"
	value = "http://${aws_instance.pp6_app.public_ip}:3000"
} 

output "comando_ssh" {
	description = "Comando para conectarse por SSH"
	value = "ssh -i pp6-clave-ssh.pem ubuntu@${aws_instance.pp6_app.public_ip}"
} 

output "clave_privada_ssh" {
	description = "Clave privada SSH (MANTENER SECRETA)"
	value = tls_private_key.pp6_key_pair.private_key_pem
	sensitive = true
}
