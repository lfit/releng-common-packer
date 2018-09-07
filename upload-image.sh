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

# Wrapper script to upload a qcow2 image to OpenStack
# If IMAGE_FILE is a URL the script will fetch the the image before uploading

OS_CLOUD="$1"
IMAGE_FILE="$2"
IMAGE_NAME="${@:3}"

if [ -z $3 ]; then
    echo "Usage: ./upload-image.sh <OS_CLOUD> <image_file> <image name>"
    exit 1
fi

if ! hash openstack; then
    echo "ERROR: openstack command not found."
fi

set -eu -o pipefail

if [[ $IMAGE_FILE == https://* ]] || [[ $IMAGE_FILE == http:// ]]; then
    TMP_FILE=$(mktemp /tmp/XXXXXX.img)
    wget -O "$TMP_FILE" "$IMAGE_FILE"
    IMAGE_FILE="$TMP_FILE"
fi

echo "Uploading $IMAGE_FILE to $OS_CLOUD as $IMAGE_NAME"
openstack image create --disk-format qcow2 --container-format bare \
    --file "$IMAGE_FILE" "$IMAGE_NAME"

if [ -z "$TMP_FILE" ]; then
    rm "$TMP_FILE"
fi
