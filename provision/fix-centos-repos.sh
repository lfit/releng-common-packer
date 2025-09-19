#!/bin/bash

# Fix CentOS EOL repository issues
# This script updates CentOS repository configurations to use vault.centos.org
# for End-of-Life CentOS versions

set -u -o pipefail
# Note: Removed -e flag to allow graceful error handling

echo "----> fix-centos-repos.sh"

# Function to check if we're on CentOS/RHEL
is_centos() {
    [[ -f /etc/redhat-release ]] && grep -qi centos /etc/redhat-release
}

is_redhat_family() {
    [[ -f /etc/redhat-release ]]
}

# Only run on CentOS systems
if ! is_redhat_family; then
    echo "Not a Red Hat family system, skipping CentOS repository fixes"
    exit 0
fi

if ! is_centos; then
    echo "Not a CentOS system, skipping CentOS repository fixes"
    exit 0
fi

echo "Detected CentOS system, checking for EOL repository issues..."

# Get CentOS version with improved detection
CENTOS_VERSION=""
if [[ -f /etc/centos-release ]]; then
    CENTOS_VERSION=$(rpm -q --queryformat '%{VERSION}' centos-release 2>/dev/null || echo "")
    echo "CentOS version from centos-release: $CENTOS_VERSION"
elif [[ -f /etc/redhat-release ]]; then
    CENTOS_VERSION=$(grep -oE '[0-9]+' /etc/redhat-release | head -1 2>/dev/null || echo "")
    echo "CentOS/RHEL version from redhat-release: $CENTOS_VERSION"
fi

# Fallback: Check /etc/os-release for stream versions
if [[ -z "$CENTOS_VERSION" && -f /etc/os-release ]]; then
    if grep -q "centos:8" /etc/os-release; then
        CENTOS_VERSION="8"
        echo "Detected CentOS 8 Stream from os-release"
    elif grep -q "centos:9" /etc/os-release; then
        CENTOS_VERSION="9"
        echo "Detected CentOS 9 Stream from os-release"
    fi
fi

if [[ -z "$CENTOS_VERSION" ]]; then
    echo "Could not determine CentOS version, attempting generic fix..."
    # Try to fix any existing CentOS repos we find
    if ls /etc/yum.repos.d/CentOS-*.repo >/dev/null 2>&1; then
        echo "Found CentOS repository files, applying generic vault fix..."
        sed -i 's|mirrorlist=http://mirrorlist.centos.org|#mirrorlist=http://mirrorlist.centos.org|g' /etc/yum.repos.d/CentOS-*.repo || true
        sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*.repo || true
        sed -i 's|baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*.repo || true
        echo "Applied generic repository fixes"
    fi
    exit 0
fi

# Fix CentOS 7 repositories (EOL)
if [[ "$CENTOS_VERSION" =~ ^7 ]]; then
    echo "Fixing CentOS 7 EOL repositories..."

    # Create vault.centos.org based repositories for CentOS 7
    cat > /etc/yum.repos.d/CentOS-Base.repo << 'EOF'
[base]
name=CentOS-7 - Base
baseurl=http://vault.centos.org/7.9.2009/os/x86_64/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
enabled=1

[updates]
name=CentOS-7 - Updates
baseurl=http://vault.centos.org/7.9.2009/updates/x86_64/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
enabled=1

[extras]
name=CentOS-7 - Extras
baseurl=http://vault.centos.org/7.9.2009/extras/x86_64/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
enabled=1

[centosplus]
name=CentOS-7 - Plus
baseurl=http://vault.centos.org/7.9.2009/centosplus/x86_64/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
EOF

    echo "Created CentOS 7 vault repository configuration"
fi

# Fix CentOS 8 Stream repositories
if [[ "$CENTOS_VERSION" =~ ^8 ]]; then
    echo "Fixing CentOS 8 Stream EOL repositories..."

    # Replace mirrorlist URLs with vault URLs in existing repo files
    if ls /etc/yum.repos.d/CentOS-*.repo >/dev/null 2>&1; then
        echo "Updating existing CentOS 8 repository files..."
        sed -i 's|mirrorlist=http://mirrorlist.centos.org|#mirrorlist=http://mirrorlist.centos.org|g' /etc/yum.repos.d/CentOS-*.repo || true
        sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*.repo || true
        sed -i 's|baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*.repo || true
    else
        echo "No CentOS repository files found, creating basic CentOS 8 Stream configuration..."
        cat > /etc/yum.repos.d/CentOS-Stream-BaseOS.repo << 'EOF'
[baseos]
name=CentOS Stream 8 - BaseOS
baseurl=http://vault.centos.org/8-stream/BaseOS/x86_64/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial

[appstream]
name=CentOS Stream 8 - AppStream
baseurl=http://vault.centos.org/8-stream/AppStream/x86_64/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
    fi

    echo "Updated CentOS 8 Stream repository configuration"
fi

# Fix CentOS 9 Stream repositories
if [[ "$CENTOS_VERSION" =~ ^9 ]]; then
    echo "Fixing CentOS 9 Stream EOL repositories..."

    # Replace mirrorlist URLs with vault URLs in existing repo files
    if ls /etc/yum.repos.d/CentOS-*.repo >/dev/null 2>&1; then
        echo "Updating existing CentOS 9 repository files..."
        sed -i 's|mirrorlist=http://mirrorlist.centos.org|#mirrorlist=http://mirrorlist.centos.org|g' /etc/yum.repos.d/CentOS-*.repo || true
        sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*.repo || true
        sed -i 's|baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*.repo || true
    else
        echo "No CentOS repository files found, creating basic CentOS 9 Stream configuration..."
        cat > /etc/yum.repos.d/CentOS-Stream-BaseOS.repo << 'EOF'
[baseos]
name=CentOS Stream 9 - BaseOS
baseurl=http://vault.centos.org/9-stream/BaseOS/x86_64/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial

[appstream]
name=CentOS Stream 9 - AppStream
baseurl=http://vault.centos.org/9-stream/AppStream/x86_64/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
    fi

    echo "Updated CentOS 9 Stream repository configuration"
fi

# Clean package manager cache
echo "Cleaning package manager cache..."
if command -v dnf >/dev/null 2>&1; then
    dnf clean all || echo "Warning: dnf clean failed"
elif command -v yum >/dev/null 2>&1; then
    yum clean all || echo "Warning: yum clean failed"
fi

echo "CentOS repository fix completed"