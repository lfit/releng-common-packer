#!/bin/bash
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2022 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################

if command -v "$(cat /tmp/.ansible_venv)/bin/ansible-playbook" &> /dev/null; then
    # shellcheck source=/dev/null
    source "$(cat /tmp/.ansible_venv)/bin/activate" && ANSIBLE_FORCE_COLOR=1 \
        PYTHONUNBUFFERED=1 "$(cat /tmp/.ansible_venv)/bin/ansible-playbook" "$@"
elif command -v "$(which ansible-playbook)"; then
    "$(which ansible-playbook)" "$@"
else
    echo "ERROR: ansible-playbook not found"
    exit
fi
