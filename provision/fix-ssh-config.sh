#!/bin/bash
# Fix SSH configuration for better Ansible compatibility on CentOS Stream 9

set -e

# Only run on CentOS 9 Stream
if ! grep -q "VERSION_ID=\"9\"" /etc/os-release || ! grep -q "centos" /etc/os-release; then
    echo "Not running on CentOS 9 Stream, skipping SSH fixes"
    exit 0
fi

echo "Applying SSH configuration fixes for CentOS 9 Stream..."

# Modify sshd_config to accept more key types
if [ -f /etc/ssh/sshd_config ]; then
    # Backup original config
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

    # Configure SSH to accept ssh-rsa keys
    if ! grep -q "^PubkeyAcceptedKeyTypes" /etc/ssh/sshd_config; then
        echo "PubkeyAcceptedKeyTypes=+ssh-rsa" >> /etc/ssh/sshd_config
    else
        sed -i 's/^PubkeyAcceptedKeyTypes.*/PubkeyAcceptedKeyTypes=+ssh-rsa/' /etc/ssh/sshd_config
    fi

    if ! grep -q "^HostKeyAlgorithms" /etc/ssh/sshd_config; then
        echo "HostKeyAlgorithms=+ssh-rsa" >> /etc/ssh/sshd_config
    else
        sed -i 's/^HostKeyAlgorithms.*/HostKeyAlgorithms=+ssh-rsa/' /etc/ssh/sshd_config
    fi

    # Ensure legacy key exchange algorithms are enabled
    if ! grep -q "^KexAlgorithms" /etc/ssh/sshd_config; then
        echo "KexAlgorithms=+diffie-hellman-group1-sha1,diffie-hellman-group14-sha1" >> /etc/ssh/sshd_config
    fi

    # Ensure password authentication is allowed
    sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config

    echo "SSH configuration updated"

    # Restart sshd to apply changes
    systemctl restart sshd
    echo "SSH service restarted"
else
    echo "SSH configuration file not found!"
    exit 1
fi

# Create flag file to indicate this script has been run
touch /var/tmp/ssh-fixed-for-ansible

echo "SSH fixes for CentOS 9 Stream completed"
exit 0
