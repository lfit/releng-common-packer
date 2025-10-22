variable "ansible_roles_path" {
  type    = string
  default = ".galaxy"
}

variable "arch" {
  type    = string
  default = "x86_64"
}

variable "aws_access_key" {
  type = string
  default = null
}

variable "aws_instance_type" {
  type    = string
  default = "t2.micro"
}

variable "aws_region" {
  type    = string
  default = "us-west-2"
}

variable "aws_secret_key" {
  type = string
  default = null
}

variable "base_image" {
  type = string
  default = null
}

variable "cloud_auth_url" {
  type    = string
  default = null
}

variable "cloud_tenant" {
  type    = string
  default = null
}

variable "cloud_user" {
  type    = string
  default = null
}

variable "cloud_pass" {
  type    = string
  default = null
}

variable "cloud_network" {
  type = string
  default = null
}

variable "cloud_region" {
  type    = string
  default = "ca-ymq-1"
}

variable "cloud_user_data" {
  type = string
  default = null
}

variable "distro" {
  type = string
  default = null
}

variable "docker_source_image" {
  type = string
  default = null
}

variable "flavor" {
  type    = string
  default = "v2-highcpu-4"
}

variable "source_ami_filter_name" {
  type    = string
  default = null
}

variable "source_ami_filter_product_code" {
  type    = string
  default = null
}

variable "source_ami_filter_owner" {
  type    = string
  default = null
}

variable "security_group_id" {
  type = string
  default = null
}

variable "ssh_proxy_host" {
  type    = string
  default = ""
}

variable "ssh_bastion_host" {
  type    = string
  default = ""
}

variable "ssh_bastion_username" {
  type    = string
  default = ""
}

variable "ssh_bastion_port" {
  type    = number
  default = 22
}

variable "ssh_bastion_agent_auth" {
  type    = bool
  default = true
}

variable "ssh_bastion_private_key_file" {
  type    = string
  default = ""
}

variable "ssh_bastion_password" {
  type    = string
  default = ""
  sensitive = true
}

variable "ssh_user" {
  type = string
  default = null
}

variable "subnet_id" {
  type = string
  default = null
}

variable "vm_image_disk_format" {
  type    = string
  default = ""
}

variable "vm_use_block_storage" {
  type    = string
  default = "true"
}

variable "vm_volume_size" {
  type    = string
  default = "20"
}

variable "vpc_id" {
  type = string
  default = null
}
