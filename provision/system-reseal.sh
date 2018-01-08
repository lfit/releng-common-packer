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
# Cleans up VM as preparation for image snapshotting

# vim: sw=2 ts=2 sts=2 et :

rm -rf ~/.viminfo \
    /etc/Pegasus/*.cnf \
    /etc/Pegasus/*.crt \
    /etc/Pegasus/*.csr \
    /etc/Pegasus/*.pem \
    /etc/Pegasus/*.srl \
    /etc/ssh/ssh*key* \
    /root/.ssh/* \
    /root/anaconda-ks.cfg \
    /root/anaconda-post.log \
    /root/initial-setup-ks.cfg \
    /root/install.log \
    /root/install.log.syslog \
    /tmp/packer \
    /var/cache/fontconfig/* \
    /var/cache/gdm/* \
    /var/cache/man/* \
    /var/lib/AccountService/users/* \
    /var/lib/cloud/* \
    /var/lib/fprint/* \
    /var/lib/logrotate.status \
    /var/log/*.log* \
    /var/log/BackupPC/LOG \
    /var/log/ConsoleKit/* \
    /var/log/anaconda.syslog \
    /var/log/anaconda/* \
    /var/log/apache2/*_log \
    /var/log/apache2/*_log-* \
    /var/log/apt/* \
    /var/log/aptitude* \
    /var/log/audit/* \
    /var/log/btmp* \
    /var/log/ceph/*.log \
    /var/log/chrony/*.log \
    /var/log/cron* \
    /var/log/cups/*_log \
    /var/log/debug* \
    /var/log/dmesg* \
    /var/log/exim4/* \
    /var/log/faillog* \
    /var/log/gdm/* \
    /var/log/glusterfs/*glusterd.vol.log \
    /var/log/glusterfs/glusterfs.log \
    /var/log/httpd/*log \
    /var/log/installer/* \
    /var/log/jetty/jetty-console.log \
    /var/log/journal/* \
    /var/log/lastlog* \
    /var/log/libvirt/libvirtd.log \
    /var/log/libvirt/lxc/*.log \
    /var/log/libvirt/qemu/*.log \
    /var/log/libvirt/uml/*.log \
    /var/log/lightdm/* \
    /var/log/mail/* \
    /var/log/maillog* \
    /var/log/messages* \
    /var/log/ntp \
    /var/log/ntpstats/* \
    /var/log/ppp/connect-errors \
    /var/log/rhsm/* \
    /var/log/sa/* \
    /var/log/secure* \
    /var/log/setroubleshoot/*.log \
    /var/log/spooler* \
    /var/log/squid/*.log \
    /var/log/syslog* \
    /var/log/tallylog* \
    /var/log/tuned/tuned.log \
    /var/log/wtmp* \
    /var/named/data/named.run

# Force a system sync and sleep to get around any SSD issues
echo "Forcing sync and sleep for 10sec"
sync
sleep 10
