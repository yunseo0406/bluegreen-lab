########################################
# Launch Configuration (스펙 기준 내에서만)
########################################

resource "ncloud_launch_configuration" "lc_blue" {
  count = var.enable_asg_blue ? 1 : 0

  name  = "${var.project}-lc-blue"
  server_image_product_code = var.server_image_product_code   
  server_product_code = var.server_product_code_manual

  login_key_name = "ncp20250904"
  init_script_no = ncloud_init_script.web_v1.id
}


########################################
# Auto Scaling Group (Blue, 3대)
########################################
resource "ncloud_auto_scaling_group" "asg_blue" {
  count                    = var.enable_asg_blue ? 1 : 0
  name                     = "${var.project}-asg-blue"
  launch_configuration_no  = ncloud_launch_configuration.lc_blue[0].id
  server_name_prefix = "blue"

  min_size           = 1
  max_size           = 3
  desired_capacity   = 3
  default_cooldown   = 180
  health_check_type_code  = "LOADB"
  health_check_grace_period = 300

  subnet_no    = ncloud_subnet.public.id
  access_control_group_no_list = [ncloud_access_control_group.web_acg.id]
  target_group_list = [ncloud_lb_target_group.ex_lb_target_group.id]
}
