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

# Library of shell functions useful in packer scripts.

# vim: ts=4 sw=4 sts=4 et tw=72 :

enable_service() {
    # Enable services for Ubuntu instances
    services=($@)

    for service in "${services[@]}"; do
        echo "---> Enable service: $service"
        FACTER_OS=$(/usr/bin/facter operatingsystem | tr '[:upper:]' '[:lower:]')
        FACTER_OSVER=$(/usr/bin/facter operatingsystemrelease)
        if [ "$FACTER_OS" == "centos" ]; then
            systemctl enable "$service"
            systemctl start "$service"
            systemctl status "$service"
        elif [ "$FACTER_OS" == "ubuntu" ]; then
            case "$FACTER_OSVER" in
                14.04)
                    service "$service" start
                    service "$service" status
                ;;
                16.04)
                    systemctl enable "$service"
                    systemctl start "$service"
                    systemctl status "$service"
                ;;
                *)
                    echo "---> Unknown Ubuntu version $FACTER_OSVER"
                    exit 1
                ;;
            esac
        else
            echo "---> Unknown OS $FACTER_OS"
            exit 1
        fi
    done
}

ensure_kernel_install() {
    # Workaround for mkinitrd failing on occassion.
    # On CentOS 7 it seems like the kernel install can fail it's mkinitrd
    # run quietly, so we may not notice the failure. This script retries for a
    # few times before giving up.
    initramfs_ver=$(rpm -q kernel | tail -1 | sed "s/kernel-/initramfs-/")
    grub_conf="/boot/grub/grub.conf"
    # Public cloud does not use /boot/grub/grub.conf and uses grub2 instead.
    if [ ! -e "$grub_conf" ]; then
        echo "$grub_conf not found. Using Grub 2 conf instead."
        grub_conf="/boot/grub2/grub.cfg"
    fi

    for i in $(seq 3); do
        if grep "$initramfs_ver" "$grub_conf"; then
            break
        fi
        echo "Kernel initrd missing. Retrying to install kernel..."
        yum reinstall -y kernel
    done
    if ! grep "$initramfs_ver" "$grub_conf"; then
        cat /boot/grub/grub.conf
        echo "ERROR: Failed to install kernel."
        exit 1
    fi
}

ensure_ubuntu_install() {
    # Workaround for mirrors occassionally failing to install a package.
    # On Ubuntu sometimes the mirrors fail to install a package. This wrapper
    # checks that a package is successfully installed before moving on.

    packages=($@)

    for pkg in "${packages[@]}"
    do
        # Retry installing package 5 times if necessary
        for i in {0..5}
        do

            # Wait for any background apt processes to finish before running apt
            while pgrep apt > /dev/null; do sleep 1; done

            echo "$i: Installing $pkg"
            if [ "$(dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -c "ok installed")" -eq 0 ]; then
                apt-cache policy "$pkg"
                apt-get install "$pkg"
                continue
            else
                echo "$pkg already installed."
                break
            fi
        done
    done
}

# If script is not sourced copy it to /tmp/lflib.sh for sourcing from other scripts
[[ $_ != $0 ]] && cp "${BASH_SOURCE[0]}" /tmp/lflib.sh || echo "---> Imported lflibs"
