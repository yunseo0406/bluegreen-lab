variable "project" {
  type    = string
  default = "blue-green-lab"
}

variable "zone" {
  type    = string
  default = "KR-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "public_lb_cidr" {
  type    = string
  default = "10.0.10.0/24"
}

variable "ssh_public_key_path" {
  type    = string
  default = "~/.ssh/ncp20250904.pub"
  
}

###############################
# asg 스위치
###############################
variable "enable_asg_blue" {
  type    = bool
  default = false   # 기본은 비활성(단일 서버만)
}

variable "attach_single_server" {
  type    = bool
  default = true    # 기본은 단일 서버를 TG에 붙여둠
}

# 콘솔에서 만든 멤버 서버 이미지 번호 (필수)
variable "server_image_product_code" {
  type    = string
  default = "" 
}

# 서버 스펙(제품코드). 모르면 나중에 -var 로 넣거나 state/콘솔에서 복사
variable "server_product_code_manual" {
  type    = string
  default = ""
}