#!/bin/bash
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2018 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
# vi: ts=4 sw=4 sts=4 et :

set -eu -o pipefail -o noglob

echo "----> install-python.sh"

# Ansible requires Python to be available so check availability and install as necessary.

function is_ubuntu()
{
    # If the file exist and contains ubuntu entry return 0
    if grep -Eq "^ID=ubuntu" /etc/os-release 2> /dev/null; then
        echo "Distro is Ubuntu"
        return 0
    fi
    echo "Distro is NOT Ubuntu"
    return 1
}

function is_centos8()
{
    # if the file exists and contains a centos:8 CPE_NAME, return 0
    if grep -Eq "^CPE_NAME=.*centos:8" /etc/os-release 2> /dev/null; then
        echo "Distro is CentOS 8"
        return 0
    fi
    echo "Distro is NOT CentOS 8"
    return 1
}

# Select fastest mirror on Ubuntu systems
function select_fastest()
{
  echo "Install netselect from debian to choose a mirror."
  apt install wget -y
  wget "http://ftp.au.debian.org/debian/pool/main/n/netselect/${NETSELECT_DEB}"
  dpkg -i "${NETSELECT_DEB}"
  apt install netselect -y

  available_mirrors=$(wget -qO - mirrors.ubuntu.com/mirrors.txt)
  using_mirror=$(grep deb /etc/apt/sources.list | grep -v \# |head -1 | awk '{print $2}')
  # SC2086 -- Double quote to prevent globbing
  # Do not double quote around ${available_mirrors} since that breaks
  # functionality
  # shellcheck disable=SC2086
  fastest_mirror=$(sudo netselect  -s 1 -t 40 ${available_mirrors}  2> /dev/null | awk '{print $2}')
  RESULT=$?
  if [ $RESULT -eq 0 ]; then
      sed -i "s#${using_mirror}#${fastest_mirror}#" /etc/apt/sources.list
      echo "Old mirror : ${using_mirror}"
      echo "New mirror : ${fastest_mirror}"
  else
      echo "NOTE: Unable to select fastest mirror"
  fi
}

# Ubuntu does not come with Python by default so we need to install it
if is_ubuntu; then
    # Use netselect to choose a package mirror to install python-minimal in a
    # reliable manner.
    # apt{-get} does not refresh the package mirrors (for packer builds run
    # within Jenkins), therefore fails with "E: Unable to locate package
    # python-minimal" while installing python-minimal.
    _ARCH="$(uname -m)"

    case $_ARCH in
        x86_64)
            source /etc/lsb-release
            if [[ ${DISTRIB_RELEASE:0:2} -lt 24 ]]; then
                NETSELECT_DEB="netselect_0.3.ds1-28+b1_amd64.deb"
                echo "NetSelect version to install is ${NETSELECT_DEB}"
                select_fastest
            fi
            ;;
        aarch64)
            #NETSELECT_DEB="netselect_0.3.ds1-28+b1_arm64.deb"
            ;;
        *)
            echo "Unknown arch ${_ARCH}. Exiting..."
            exit 1
    esac


    echo "Update and Remove unwanted packages..."
    apt clean all -y
    apt -y update

    echo "Installing Python..."
    # Ubuntu 20.04 and newer can default to Python 3
    if apt-cache show python-is-python3; then
        apt-get install -y python-is-python3
        type python3
    else
        apt-get install -y python-minimal
        type python
    fi
fi

if is_centos8; then
    echo "Clean up deprecated repos"
    sed -i s/mirror.centos.org/vault.centos.org/g /etc/yum.repos.d/CentOS-*.repo
    sed -i s/^#.*baseurl=http/baseurl=http/g /etc/yum.repos.d/CentOS-*.repo
    sed -i s/^mirrorlist=http/#mirrorlist=http/g /etc/yum.repos.d/CentOS-*.repo

    echo "Install python38"
    dnf clean all
    dnf install -y python38
    python3 -V
    type python3
fi


# Ansible requires sudo so ensure it is available.
if ! command -v sudo; then
    if command -v apt-get; then
        apt-get install -y sudo
    elif command -v yum; then
        yum install -y sudo
    fi
fi
type sudo
