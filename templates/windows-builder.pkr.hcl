packer {
  required_plugins {
    openstack = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/openstack"
    }
  }
}

variable "ansible_roles_path" {
  type    = string
  default = ".galaxy"
}

variable "arch" {
  type    = string
  default = "x86_64"
}

variable "base_image" {
  type = string
}

variable "cloud_network" {
  type = string
}

variable "cloud_region" {
  type    = string
  default = "ca-ymq-1"
}

variable "cloud_user_data" {
  type = string
}

variable "distro" {
  type = string
}

variable "flavor" {
  type    = string
  default = "v2-highcpu-4"
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

source "openstack" "windows-builder" {
  communicator      = "winrm"
  flavor            = "${var.flavor}"
  image_disk_format = "${var.vm_image_disk_format}"
  image_name        = "ZZCI - ${var.distro} - win-builder - ${var.arch} - ${legacy_isotime("20060102-150405.000")}"
  instance_name     = "${var.distro}-win-builder-${uuidv4()}"
  metadata = {
    ci_managed = "yes"
  }
  networks                = ["${var.cloud_network}"]
  region                  = "${var.cloud_region}"
  source_image_name       = "${var.base_image}"
  use_blockstorage_volume = "${var.vm_use_block_storage}"
  user_data_file          = "${var.cloud_user_data}"
  volume_size             = "${var.vm_volume_size}"
  winrm_insecure          = true
  winrm_password          = "W!nRMB00tStrap."
  winrm_timeout           = "3600s"
  winrm_use_ssl           = true
  winrm_username          = "Administrator"
}

build {
  sources = ["source.openstack.windows-builder"]

  provisioner "ansible" {
    extra_arguments = ["--connection", "packer", "--extra-vars", "ansible_shell_type=powershell ansible_shell_executable=None", "--scp-extra-args", "'-O'", "--ssh-extra-args", "-o IdentitiesOnly=yes -o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedAlgorithms=+ssh-rsa"]
    playbook_file   = "provision/local-windows-builder.yaml"
  }
}
