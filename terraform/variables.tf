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