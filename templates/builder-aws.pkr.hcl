packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.6"
      source  = "github.com/hashicorp/amazon"
    }
  }
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
}

variable "cloud_user_data" {
  type = string
}

variable "distro" {
  type = string
}

variable "security_group_id" {
  type = string
}

variable "source_ami_filter_name" {
  type = string
}

variable "source_ami_filter_owner" {
  type = string
}

variable "source_ami_filter_product_code" {
  type = string
}

variable "ssh_proxy_host" {
  type    = string
  default = ""
}

variable "ssh_user" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "vpc_id" {
  type = string
}

data "amazon-ami" "builder-aws" {
  access_key = "${var.aws_access_key}"
  filters = {
    name                = "${var.source_ami_filter_name}"
    product-code        = "${var.source_ami_filter_product_code}"
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }
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
    ansible_env_vars   = [
        "ANSIBLE_NOCOWS=1",
        "ANSIBLE_PIPELINING=False",
        "ANSIBLE_HOST_KEY_CHECKING=False",
        "ANSIBLE_ROLES_PATH=${var.ansible_roles_path}",
        "ANSIBLE_CALLBACK_WHITELIST=profile_tasks",
        "ANSIBLE_STDOUT_CALLBACK=debug"
    ]
    command            = "./common-packer/ansible-playbook.sh"
    extra_arguments    = [
        "--scp-extra-args", "'-O'",
        "--ssh-extra-args", "-o IdentitiesOnly=yes -o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedAlgorithms=+ssh-rsa"
    ]
    playbook_file      = "provision/local-builder.yaml"
    skip_version_check = true
    user               = "${var.ssh_user}"
  }
}
