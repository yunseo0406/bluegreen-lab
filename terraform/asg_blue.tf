resource "ncloud_launch_configuration" "lc_blue" {
  count = var.enable_asg_blue ? 1 : 0

  name                       = "${var.project}-lc-blue"
  # ✅ API로 만든 이미지의 product code 사용
  server_image_product_code  = var.server_image_product_code
  server_product_code        = var.server_product_code
  login_key_name             = "ncp20250904"

  lifecycle {
    precondition {
      condition     = length(trimspace(var.server_image_product_code)) > 0
      error_message = "server_image_product_code 가 비었습니다."
    }
    precondition {
      condition     = length(trimspace(var.server_product_code)) > 0
      error_message = "server_product_code 가 비었습니다."
    }
  }
}

resource "ncloud_auto_scaling_group" "asg_blue" {
  count = var.enable_asg_blue ? 1 : 0

  name                    = "${var.project}-asg-blue"
  launch_configuration_no = ncloud_launch_configuration.lc_blue[0].launch_configuration_no
  server_name_prefix      = "blue"

  min_size = 3
  max_size = 3
  desired_capacity = 3

  subnet_no                    = ncloud_subnet.public.id
  access_control_group_no_list = [ncloud_access_control_group.web_acg.id]

  health_check_type_code    = "LOADB"
  health_check_grace_period = 300
  target_group_list         = [ncloud_lb_target_group.ex_lb_target_group.id]

  default_cooldown          = 180
  wait_for_capacity_timeout = "10m"
}