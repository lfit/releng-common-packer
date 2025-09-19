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

set -eu -o pipefail -o noglob

echo "----> ansible-galaxy.sh"

wget -q https://raw.githubusercontent.com/lfit/releng-global-jjb/master/jenkins-init-scripts/lf-env.sh \
    -O ~/lf-env.sh

# shellcheck disable=SC1090
. ~/lf-env.sh

# ansible-galaxy.sh runs before pyenv is installed, so use available system Python
# The lfit.python-install role will install pyenv later in the build process
if command -v python3 >/dev/null 2>&1; then
    lf-activate-venv --python python3 --venv-file "/tmp/.ansible_venv" \
        ansible~=9.2.0
elif command -v python >/dev/null 2>&1; then
    lf-activate-venv --python python --venv-file "/tmp/.ansible_venv" \
        ansible~=9.2.0
else
    echo "ERROR: No Python interpreter found (python3 or python)"
    exit 1
fi

ansible_roles_path=${1:-.galaxy}
ansible_requirements_file=${2:-requirements.yaml}
script_dir=$(dirname "$0")

cmd="ansible-galaxy install -p $ansible_roles_path -r \
         $script_dir/requirements.yaml"
echo "Running: $cmd"
$cmd

# Check for local requirements file
if [[ -f $ansible_requirements_file ]]; then
    cmd="ansible-galaxy install -p $ansible_roles_path -r \
             $ansible_requirements_file"
    echo "Running: $cmd"
    $cmd
fi
