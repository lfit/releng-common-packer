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

# Ansible requires Python 2 so check availability and install as necessary.
# Ubuntu 16.04 does not come with Python 2 by default

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

if is_ubuntu; then
    # Use netselect to choose a package mirror to install python-minimal in a
    # reliable manner.
    # apt{-get} does not refresh the package mirrors (for packer builds run
    # within Jenkins), therefore fails with "E: Unable to locate package
    # python-minimal" while installing python-minimal.
    _MAIN_VERSION="$(echo "$PACKER_PLATFORM" | awk -F- '{print $2}' | awk -F. '{print $1}')"
    case $_MAIN_VERSION in 
	    16)
		   NETSELECT_DEB="netselect_0.3.ds1-26_amd64.deb"
		   ;;
	    18)
		   NETSELECT_DEB="netselect_0.3.ds1-28+b1_amd64.deb"
		   ;;
            *)
                   echo "Ubuntu version is not 16 nor 18. exiting"
		   exit 1
    esac

    echo "NetSelect version to install is ${NETSELECT_DEB}"

    echo "Install netselect from debian to choose a mirror."
    apt install wget -y
    wget http://ftp.au.debian.org/debian/pool/main/n/netselect/${NETSELECT_DEB}
    dpkg -i ${NETSELECT_DEB}
    apt install netselect -y
    if ! netselect -s 20 -t 40 "$(wget -qO - mirrors.ubuntu.com/mirrors.txt)"; then
        echo "NOTE: Unable to refresh 'sources.list'"
    fi
    sed -i 's#http://us.archive.ubuntu.com/ubuntu#http://ubuntu.uberglobalmirror.com/archive#' \
        /etc/apt/sources.list

    echo "Installing python-minimal..."
    apt clean all -y
    apt -y update
    apt install -y python-minimal
fi

type python
type sudo
