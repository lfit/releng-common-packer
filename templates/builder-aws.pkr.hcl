packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.6"
      source  = "github.com/hashicorp/amazon"
    }
    ansible = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

variable "ansible_roles_path" {
  type    = string
  default = ".galaxy"
}

variable "local_build" {
  type        = bool
  default     = false
  description = "Set to true for local builds to enable SSH compatibility options"
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
  type    = string
  default = null
}

variable "cloud_auth_url" {
  type    = string
  default = null
}

variable "cloud_user_data" {
  type = string
  default = null
}

variable "cloud_network" {
  type    = string
  default = null
}

variable "cloud_tenant" {
  type    = string
  default = null
}

variable "cloud_pass" {
  type    = string
  default = null
}

variable "cloud_user" {
  type    = string
  default = null
}

variable "distro" {
  type = string
  default = null
}

variable "docker_source_image" {
  type    = string
  default = null
}

variable "flavor" {
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

variable "ssh_user" {
  type = string
  default = null
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

variable "subnet_id" {
  type = string
  default = null
}

variable "vpc_id" {
  type = string
  default = null
}

locals {
  # SSH arguments for local builds only
  ssh_extra_args = var.local_build ? [
    "--scp-extra-args", "'-O'",
    "--ssh-extra-args",
    "-o IdentitiesOnly=yes -o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedAlgorithms=+ssh-rsa",
  ] : [
    "--ssh-extra-args", "-o IdentitiesOnly=yes -o HostKeyAlgorithms=+ssh-rsa",
  ]

  # Ansible environment variables - conditional pipelining for bastion builds
  ansible_env_vars = var.local_build ? [
    "ANSIBLE_NOCOWS=1",
    "ANSIBLE_PIPELINING=True",
    "ANSIBLE_HOST_KEY_CHECKING=False",
    "ANSIBLE_SCP_IF_SSH=True",
    "ANSIBLE_ROLES_PATH=${var.ansible_roles_path}",
    "ANSIBLE_CALLBACK_WHITELIST=profile_tasks",
    "ANSIBLE_STDOUT_CALLBACK=debug"
  ] : [
    "ANSIBLE_NOCOWS=1",
    "ANSIBLE_PIPELINING=False",
    "ANSIBLE_HOST_KEY_CHECKING=False",
    "ANSIBLE_ROLES_PATH=${var.ansible_roles_path}",
    "ANSIBLE_CALLBACK_WHITELIST=profile_tasks",
    "ANSIBLE_STDOUT_CALLBACK=debug"
  ]
}

data "amazon-ami" "builder-aws" {
  access_key = "${var.aws_access_key}"
  filters = merge(
    {
      name                = "${var.source_ami_filter_name}"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    },
    var.source_ami_filter_product_code != "" && var.source_ami_filter_product_code != null ? {
      product-code = "${var.source_ami_filter_product_code}"
    } : {}
  )
  most_recent = true
  owners      = ["${var.source_ami_filter_owner}"]
  region      = "${var.aws_region}"
  secret_key  = "${var.aws_secret_key}"
}

source "amazon-ebs" "aws" {
  access_key        = "${var.aws_access_key}"
  ami_name          = "ZZCI - ${var.distro} - builder-aws - ${var.arch} - ${legacy_isotime("20060102-150405.000")}"
  instance_type     = "${var.aws_instance_type}"
  region            = "${var.aws_region}"
  secret_key        = "${var.aws_secret_key}"
  security_group_id = "${var.security_group_id}"
  source_ami        = "${data.amazon-ami.builder-aws.id}"
  ssh_proxy_host    = "${var.ssh_proxy_host}"
  ssh_username      = "${var.ssh_user}"
  subnet_id         = "${var.subnet_id}"
  user_data_file    = "${var.cloud_user_data}"
  vpc_id            = "${var.vpc_id}"

  # Enable enhanced networking (SR-IOV is automatic with ENA and modern instance types)
  ena_support       = true

  # Allow IMDSv1 for compatibility with older Jenkins plugins
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "optional"  # Allows both v1 and v2
    http_put_response_hop_limit = 1
  }

  # Configure root volume with 20GB to provide sufficient space for Jenkins builds
  launch_block_device_mappings {
    device_name = "/dev/sda1"
    volume_size = 20
    volume_type = "gp2"
    delete_on_termination = true
  }
}

build {
  description = "Build an AMI for use as a CI builder"

  sources = ["source.amazon-ebs.aws"]

  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; if [ \"$UID\" == \"0\" ]; then {{ .Vars }} '{{ .Path }}'; else {{ .Vars }} sudo -E '{{ .Path }}'; fi"
    scripts         = ["common-packer/provision/install-python.sh"]
  }

  provisioner "shell-local" {
    command = "./common-packer/ansible-galaxy.sh ${var.ansible_roles_path}"
  }

  provisioner "ansible" {
    ansible_env_vars   = local.ansible_env_vars
    command            = "./common-packer/ansible-playbook.sh"
    extra_arguments    = local.ssh_extra_args
    playbook_file      = "provision/local-builder.yaml"
    skip_version_check = true
    user               = "${var.ssh_user}"
  }
}
