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

# Ansible requires Python 2 so check availability and install as necessary.
if ! command -v /usr/bin/python; then
    # Ubuntu 16.04 does not come with Python 2 by default.
    if command -v apt; then
        apt -y update
        apt install -y python-minimal
    fi
fi
