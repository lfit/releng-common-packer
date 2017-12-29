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

# Handle the occurance where SELINUX is actually disabled
SELINUX=$(grep -E '^SELINUX=(disabled|permissive|enforcing)$' /etc/selinux/config)
MODE=$(echo "$SELINUX" | cut -f 2 -d '=')
case "$MODE" in
    permissive)
        echo "************************************"
        echo "** SYSTEM ENTERING ENFORCING MODE **"
        echo "************************************"
        # make sure that the filesystem is properly labelled.
        # it could be not fully labeled correctly if it was just switched
        # from disabled, the autorelabel misses some things
        # skip relabelling on /dev as it will generally throw errors
        restorecon -R -e /dev /

        # enable enforcing mode from the very start
        setenforce enforcing

        # configure system for enforcing mode on next boot
        sed -i 's/SELINUX=permissive/SELINUX=enforcing/' /etc/selinux/config
    ;;
    disabled)
        sed -i 's/SELINUX=disabled/SELINUX=permissive/' /etc/selinux/config
        touch /.autorelabel

        echo "*******************************************"
        echo "** SYSTEM REQUIRES A RESTART FOR SELINUX **"
        echo "*******************************************"
    ;;
    enforcing)
        echo "*********************************"
        echo "** SYSTEM IS IN ENFORCING MODE **"
        echo "*********************************"
    ;;
esac
