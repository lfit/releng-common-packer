source_ami_filter_name = "*CentOS-cs-9*"
source_ami_filter_owner = "aws-marketplace"
source_ami_filter_product_code = "0454011e44daf8e6d"
base_image = "CentOS Stream 9 (x86_64) [2023-03-27]
distro = "CentOS Stream 9"
docker_source_image = "centos:9"
ssh_user = "cloud-user"
cloud_user_data = "common-packer/provision/rh-user_data.sh"
