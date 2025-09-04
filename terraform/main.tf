terraform {
  required_providers {
    ncloud = {
      source = "NaverCloudPlatform/ncloud"
    }
  }
  required_version = ">= 0.13"
}

provider "ncloud" {
  region      = "KR"
  site        = "public"
  support_vpc = true
}

resource "ncloud_vpc" "this" {
  name            = "${var.project}-vpc"
  ipv4_cidr_block = var.vpc_cidr
}

# Public Subnet (Web)
resource "ncloud_subnet" "public" {
  name           = "${var.project}-pub"
  vpc_no         = ncloud_vpc.this.id
  subnet         = var.public_cidr
  zone           = var.zone
  subnet_type    = "PUBLIC"
  usage_type     = "GEN"
  network_acl_no = ncloud_vpc.this.default_network_acl_no
}

# External LB 전용 Subnet (Public)
resource "ncloud_subnet" "public_lb" {
  name           = "${var.project}-pub-lb"
  vpc_no         = ncloud_vpc.this.id
  subnet         = var.public_lb_cidr
  zone           = var.zone
  subnet_type    = "PUBLIC"
  usage_type     = "LOADB"
  network_acl_no = ncloud_vpc.this.default_network_acl_no
}

# server image and spec data sources
data "ncloud_server_image_numbers" "kvm-image" {
  server_image_name = "ubuntu-22.04-base"
  filter {
    name   = "hypervisor_type"
    values = ["KVM"]
  }
}

data "ncloud_server_specs" "kvm-spec" {
  filter {
    name   = "server_spec_code"
    values = ["s2-g3"]
  }
}

resource "ncloud_access_control_group" "web_acg" {
  name   = "${var.project}-web-acg"
  vpc_no = ncloud_vpc.this.id
}

resource "ncloud_access_control_group_rule" "web_rule" {
  access_control_group_no = ncloud_access_control_group.web_acg.id

  inbound {
    protocol   = "TCP"
    ip_block   = "0.0.0.0/0"
    port_range = "22"
  }

  inbound {
    protocol   = "TCP"
    ip_block   = var.public_lb_cidr
    port_range = "80"
  }

  outbound {
    protocol   = "TCP"
    ip_block   = "0.0.0.0/0"
    port_range = "1-65535"
  }
}

resource "ncloud_server" "web" {
  name                = "${var.project}-web"
  subnet_no           = ncloud_subnet.public.id
  server_image_number = data.ncloud_server_image_numbers.kvm-image.image_number_list.0.server_image_number
  server_spec_code    = data.ncloud_server_specs.kvm-spec.server_spec_list.0.server_spec_code
  login_key_name = "ncp20250904"

  network_interface {
    network_interface_no = ncloud_network_interface.web_nic.id
    order                = 0
  }
}

resource "ncloud_network_interface" "web_nic" {
  name                  = "web-nic"
  subnet_no             = ncloud_subnet.public.id
  access_control_groups = [ncloud_access_control_group.web_acg.id]
}
# 공인 ip
resource "ncloud_public_ip" "web_eip" {
  server_instance_no = ncloud_server.web.id
}

resource "ncloud_lb" "external_lb" {
  name           = "external-lb-${var.project}"
  network_type   = "PUBLIC"
  type           = "APPLICATION"
  subnet_no_list = [ncloud_subnet.public_lb.id]
}

# external lb target group
resource "ncloud_lb_target_group" "ex_lb_target_group" {
  vpc_no      = ncloud_vpc.this.id
  protocol    = "HTTP"
  target_type = "VSVR"
  port        = "80"
  health_check {
    protocol       = "HTTP"
    http_method    = "GET"
    port           = "80"
    url_path       = "/"
    cycle          = 30
    up_threshold   = 2
    down_threshold = 2
  }
  algorithm_type = "RR"
}

# external lb listener
resource "ncloud_lb_listener" "ex_lb_listener" {
  load_balancer_no = ncloud_lb.external_lb.id
  protocol         = "HTTP"
  port             = 80
  target_group_no  = ncloud_lb_target_group.ex_lb_target_group.id
}

# external lb target group attachment
resource "ncloud_lb_target_group_attachment" "ex_lb_target_group_attach" {
  target_group_no = ncloud_lb_target_group.ex_lb_target_group.id
  target_no_list  = [ncloud_server.web.id]

  depends_on = [
    ncloud_lb_target_group.ex_lb_target_group,
    ncloud_server.web
  ]
}