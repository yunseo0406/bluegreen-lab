output "alb_domain"      { value = ncloud_lb.alb.domain }
output "base_public_ip"  { value = ncloud_public_ip.base_eip.public_ip }
output "base_server_no"  { value = ncloud_server.base.id }
