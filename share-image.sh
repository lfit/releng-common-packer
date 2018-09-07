#!/bin/bash
# SPDX-License-Identifier: MIT
##############################################################################
# Copyright (c) 2018 The Linux Foundation and others.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
##############################################################################

# Wrapper script to share an image to other OpenStack tenants

IMAGE="$1"
SRC_CLOUD="$2"
DEST_CLOUD="${@:3}"

if [ -z $2 ]; then
    echo "Usage: ./share-image.sh <image> <src_cloud> [dest_cloud [...]]"
    exit 1
fi

if ! hash openstack; then
    echo "ERROR: openstack command not found."
fi

set -eu -o pipefail

if [ -z "$DEST_CLOUD" ]; then
    # opendaylight is assumed to be the source cloud
    DEST_CLOUD=(
        acumos
        akraino
        aswf
        edgex
        fdio
        hyperledger
        onap
    )
fi

echo "Marking $IMAGE as shared."
image_id=$(openstack --os-cloud ${SRC_CLOUD} image list \
    --name "$IMAGE" -f value -c ID)
openstack --os-cloud "${SRC_CLOUD}" image set --shared "${image_id}"

for cloud in ${DEST_CLOUD[@]}; do
    echo "Sharing to $cloud"
    token=$(openstack --os-cloud ${cloud} token issue -c project_id -f value)
    openstack --os-cloud "${SRC_CLOUD}" image add project "${image_id}" "$token"
    openstack --os-cloud "${cloud}" image set --accept "${image_id}"
done
