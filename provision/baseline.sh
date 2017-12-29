#!/bin/bash
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2016 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################

# vim: ts=4 sw=4 sts=4 et tw=72 :

# Import shared functions
source /tmp/lflib.sh

# force any errors to cause the script and job to end in failure
set -xeu -o pipefail

prepare_system() {
    echo "---> Attempting to detect OS"

    # upstream cloud images use the distro name as the initial user
    ORIGIN=$(if [ -e /etc/redhat-release ]
        then
            echo redhat
        else
            echo ubuntu
        fi)

    case "${ORIGIN}" in
        fedora|centos|redhat)
            echo "---> RH type system detected"
            prepare_centos_system
        ;;
        ubuntu)
            echo "---> Ubuntu system detected"
            prepare_ubuntu_system
        ;;
        *)
            echo "---> Unknown operating system"
        ;;
    esac
}

prepare_centos_system() {
    # Allow jenkins access to alternatives command to switch java version
    cat <<EOF >/etc/sudoers.d/89-jenkins-user-defaults
Defaults:jenkins !requiretty
jenkins ALL = NOPASSWD: /usr/sbin/alternatives
EOF

    echo "---> Updating operating system"
    yum clean all
    yum install -y deltarpm
    yum update -y
    ensure_kernel_install

    echo "---> Installing base packages"
    yum install -y @base https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

    echo "---> Installing factor"
    # puppet4 install removes factor so use the version provided by puppet.
    rpm -ivh https://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm
    yum -y install -y puppet-agent
    ln -sf /opt/puppetlabs/bin/facter /usr/bin/facter
    ln -sf /opt/puppetlabs/puppet/bin/puppet /usr/bin/puppet
    export PATH="/opt/puppetlabs/bin/:$PATH"
}

finalize_system() {
    # To handle the prompt style that is expected all over the environment
    # with how use use robotframework we need to make sure that it is
    # consistent for any of the users that are created during dynamic spin
    # ups
    echo 'PS1="[\u@\h \W]> "' >> /etc/skel/.bashrc

    # Update /etc/nss-switch.conf to map hostname with IP instead of using `localhost`
    # from /etc/hosts which is required by some of the Java API's to avoid
    # Java UnknownHostException: "Name or service not known" error.
    sed -i "/^hosts:/s/$/ myhostname/" /etc/nsswitch.conf
}

##################
## Script Start ##
##################

prepare_system

# Package install functions

finalize_system
