output "web_public_ip" {
  value = ncloud_public_ip.web_eip.public_ip
}

output "alb_domain" {
  value = ncloud_lb.external_lb.domain
}
