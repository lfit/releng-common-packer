source_ami_filter_name = "*CentOS-cs-8*"
source_ami_filter_owner = "aws-marketplace"
source_ami_filter_product_code = "0418c980c296f36ce"
base_image = "CentOS Stream 8 (x86_64) [2022-01-25]"
distro = "CentOS Stream 8"
docker_source_image = "centos:8"
ssh_user = "centos"
cloud_user_data = "common-packer/provision/rh-user_data.sh"