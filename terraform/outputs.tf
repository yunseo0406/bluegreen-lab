output "web_public_ip" {
  value = ncloud_public_ip.web_eip.public_ip
}

output "alb_domain" {
  value = ncloud_lb.external_lb.domain
}

output "web_server_instance_no" {
  value = ncloud_server.web.id # = server_instance_no
}
