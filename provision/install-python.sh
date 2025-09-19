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

function is_centos7()
{
    # if the file exists and contains a centos:7 CPE_NAME, return 0
    if grep -Eq "^CPE_NAME=.*centos:7" /etc/os-release 2> /dev/null; then
        echo "Distro is CentOS 7"
        return 0
    fi
    # Alternative check if CPE_NAME doesn't exist or doesn't have version
    if grep -Eq "^VERSION_ID=\"7" /etc/os-release 2> /dev/null && grep -Eq "^ID=\"centos\"" /etc/os-release 2> /dev/null; then
        echo "Distro is CentOS 7 (VERSION_ID method)"
        return 0
    fi
    echo "Distro is NOT CentOS 7"
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

function is_centos9()
{
    # if the file exists and contains a centos:9 CPE_NAME, return 0
    if grep -Eq "^CPE_NAME=.*centos:9" /etc/os-release 2> /dev/null; then
        echo "Distro is CentOS 9"
        return 0
    fi
    echo "Distro is NOT CentOS 9"
    return 1
}

# Select fastest mirror on Ubuntu systems
function select_fastest()
{
  echo "Install netselect from debian to choose a mirror."
  apt install wget -y
  wget "http://deb.debian.org/debian/pool/main/n/netselect/${NETSELECT_DEB}"
  dpkg -i "${NETSELECT_DEB}"
  apt install netselect -y

  available_mirrors=$(wget -qO - mirrors.ubuntu.com/mirrors.txt 2>/dev/null)
  if [ -z "$available_mirrors" ]; then
      echo "NOTE: Unable to fetch mirror list, continuing with default mirror"
      return 0
  fi

  using_mirror=$(grep deb /etc/apt/sources.list | grep -v \# |head -1 | awk '{print $2}')
  if [ -z "$using_mirror" ]; then
      echo "NOTE: Unable to determine current mirror, continuing with default"
      return 0
  fi

  # SC2086 -- Double quote to prevent globbing
  # Do not double quote around ${available_mirrors} since that breaks
  # functionality
  # shellcheck disable=SC2086
  fastest_mirror=$(timeout 60 sudo netselect  -s 1 -t 40 ${available_mirrors}  2> /dev/null | awk '{print $2}')
  RESULT=$?
  if [ $RESULT -eq 0 ] && [ -n "$fastest_mirror" ]; then
      sed -i "s#${using_mirror}#${fastest_mirror}#" /etc/apt/sources.list
      echo "Old mirror : ${using_mirror}"
      echo "New mirror : ${fastest_mirror}"
  else
      echo "NOTE: Unable to select fastest mirror (timeout or no response), continuing with current mirror: ${using_mirror}"
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
            # Select netselect version based on Ubuntu release and libc6 compatibility
            case ${DISTRIB_RELEASE:0:2} in
                16|18|20)
                    # Ubuntu 20.04 and earlier have libc6 < 2.34
                    NETSELECT_DEB="netselect_0.3.ds1-29_amd64.deb"
                    ;;
                22)
                    # Ubuntu 22.04 has libc6 >= 2.34
                    NETSELECT_DEB="netselect_0.3.ds1-30.1_amd64.deb"
                    ;;
                24)
                    # Ubuntu 24.04: Skip netselect due to timeout issues with latest version
                    # The default mirrors are usually fast enough for Ubuntu 24.04
                    echo "Skipping netselect for Ubuntu 24.04 due to compatibility issues"
                    echo "Using default Ubuntu 24.04 mirrors"
                    ;;
                *)
                    # Default to older version for unknown releases
                    NETSELECT_DEB="netselect_0.3.ds1-29_amd64.deb"
                    echo "NetSelect version to install is ${NETSELECT_DEB}"
                    select_fastest
                    ;;
            esac

            # Only call select_fastest for versions that need it (exclude Ubuntu 24.04)
            case ${DISTRIB_RELEASE:0:2} in
                16|18|20|22)
                    echo "NetSelect version to install is ${NETSELECT_DEB}"
                    select_fastest
                    ;;
            esac
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
        apt-get install -y python-is-python3 python3-pip
        pip3 install --upgrade pip
        pip3 install paramiko
        python3 -c "import paramiko; print('Paramiko installed successfully')"
        type python3
    else
        apt-get install -y python-minimal python-pip
        pip install --upgrade pip
        pip install paramiko
        python -c "import paramiko; print('Paramiko installed successfully')"
        type python
    fi
fi

if is_centos8; then
    echo "Clean up deprecated repos"
    # Remove ALL existing repository files and clear cache completely
    rm -f /etc/yum.repos.d/*.repo 2>/dev/null || true
    rm -rf /var/cache/dnf/* 2>/dev/null || true
    rm -rf /var/cache/yum/* 2>/dev/null || true
    dnf clean all 2>/dev/null || true

    # Create clean CentOS 8 Stream repositories using vault.centos.org
    cat > /etc/yum.repos.d/CentOS-Stream-BaseOS.repo << 'EOF'
[baseos]
name=CentOS Stream 8 - BaseOS
baseurl=https://vault.centos.org/8.5.2111/BaseOS/x86_64/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF

    cat > /etc/yum.repos.d/CentOS-Stream-AppStream.repo << 'EOF'
[appstream]
name=CentOS Stream 8 - AppStream
baseurl=https://vault.centos.org/8.5.2111/AppStream/x86_64/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF

    cat > /etc/yum.repos.d/CentOS-Stream-Extras.repo << 'EOF'
[extras]
name=CentOS Stream 8 - Extras
baseurl=https://vault.centos.org/8.5.2111/extras/x86_64/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF

    cat > /etc/yum.repos.d/CentOS-Stream-PowerTools.repo << 'EOF'
[powertools]
name=CentOS Stream 8 - PowerTools
baseurl=https://vault.centos.org/8.5.2111/PowerTools/x86_64/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
    echo "Created clean CentOS 8 Stream repository configuration"

    echo "Downgrade packages to match repository versions"
    dnf makecache
    dnf distro-sync -y --allowerasing || {
        echo "Warning: distro-sync failed, trying package downgrade"
        dnf downgrade -y glibc glibc-common glibc-devel glibc-headers || true
    }

    echo "Install python38"
    dnf makecache

    # Install EPEL repository for additional packages
    echo "Installing EPEL repository"
    dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm || {
        echo "Warning: EPEL installation failed, continuing without EPEL"
    }

    dnf install -y python38 || {
        echo "ERROR: Failed to install python38, checking repository status..."
        dnf repolist
        echo "Attempting to install python3 as fallback..."
        dnf install -y python3
    }

    # Install pip and paramiko for Ansible
    dnf install -y python3-pip
    pip3 install --upgrade pip
    pip3 install paramiko

    # Verify installation
    python3 -c "import paramiko; print('Paramiko installed successfully')"
    python3 -V
    type python3
fi

if is_centos9; then
    echo "Clean up deprecated repos for CentOS 9"
    # Remove ALL existing repository files and clear cache completely
    rm -f /etc/yum.repos.d/*.repo 2>/dev/null || true
    rm -rf /var/cache/dnf/* 2>/dev/null || true
    rm -rf /var/cache/yum/* 2>/dev/null || true
    dnf clean all 2>/dev/null || true

    # Disable all repositories to prevent conflicts
    dnf config-manager --set-disabled "*" 2>/dev/null || true

    # Remove any cached repository metadata
    rm -rf /var/lib/dnf/* 2>/dev/null || true

    # Create clean CentOS 9 Stream repositories using mirror.stream.centos.org
    cat > /etc/yum.repos.d/CentOS-Stream-BaseOS.repo << 'EOF'
[baseos]
name=CentOS Stream 9 - BaseOS
baseurl=https://mirror.stream.centos.org/9-stream/BaseOS/x86_64/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF

    cat > /etc/yum.repos.d/CentOS-Stream-AppStream.repo << 'EOF'
[appstream]
name=CentOS Stream 9 - AppStream
baseurl=https://mirror.stream.centos.org/9-stream/AppStream/x86_64/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF

    cat > /etc/yum.repos.d/CentOS-Stream-CRB.repo << 'EOF'
[crb]
name=CentOS Stream 9 - CRB
baseurl=https://mirror.stream.centos.org/9-stream/CRB/x86_64/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF

# Extras-common repository no longer exists in CentOS Stream 9 as of Sept 2025
# Removed to fix 404 errors during build process
    echo "Created clean CentOS 9 Stream repository configuration"

    echo "Install python3 for CentOS 9"
    dnf makecache

    # Install EPEL repository for additional packages
    echo "Installing EPEL repository"
    dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm || {
        echo "Warning: EPEL installation failed, continuing without EPEL"
    }

    dnf install -y python3 python3-pip || {
        echo "ERROR: Failed to install python3, checking repository status..."
        dnf repolist
        exit 1
    }

    # Install paramiko for Ansible
    pip3 install --upgrade pip
    pip3 install paramiko

    # Verify installation
    python3 -c "import paramiko; print('Paramiko installed successfully')"
    python3 -V
    type python3
fi

# Install Python and paramiko for CentOS 7
if is_centos7; then
    echo "Install Python and paramiko for CentOS 7"
    # Ensure python is installed
    if ! command -v python; then
        yum install -y python python-devel
    fi

    # Install pip if not available
    if ! command -v pip; then
        yum install -y epel-release
        yum install -y python-pip
    fi

    # Install paramiko for Ansible SSH
    pip install --upgrade pip
    pip install paramiko

    # Verify installation
    python -c "import paramiko; print('Paramiko installed successfully')"

    # Make sure python is in path
    python -V
    type python
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
