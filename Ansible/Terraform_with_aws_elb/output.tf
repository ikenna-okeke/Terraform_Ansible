output "my_security_group" {
  value = aws_security_group.http_server_sg
}

output "http_server_public_dns" {
  value = aws_instance.http_servers
}
output "public_dns" {
  value = values(aws_instance.http_servers).*.id #you dont really see this in the main.tf file but just go to the terraform controla and run aws_instance.http_server and you see everything under it
}