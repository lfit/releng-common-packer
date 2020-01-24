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
    # TODO: Find out what is causing apt unable to refresh the package source
    # which results in "E: Unable to locate package python-minimal" seen only
    # on the Jenkins packer jobs and not local packer builds.
    # This may have todo with apt overriding the package_mirrors variables
    # (%availability_zone, %region) required in /etc/cloud/cloud.cfg.
    echo "Installing python-minimal..."
    apt-get clean all -y
    apt-get -y update
    apt-get install -y python-minimal
fi

type python
type sudo
