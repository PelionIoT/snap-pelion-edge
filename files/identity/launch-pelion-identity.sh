#!/bin/bash
# ----------------------------------------------------------------------------
# Copyright (c) 2020, Pelion and affiliates.
#
# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ----------------------------------------------------------------------------

# $1: install path to the parent of the wigwag folder (i.e., SNAP)
# $2: destination path to RW storage (i.e., SNAP_DATA)

IDENTITY_JSON_DIR=${2}/userdata/edge_gw_identity
export IDENTITY_JSON=${IDENTITY_JSON_DIR}/identity.json

LOCKFILE=/tmp/wait-for-pelion-identity.lck
(
    # only run one instance of generate-identity.sh at a time
    flock -w 30 9 || exit 1

    IDENTITY_JSON_CREATED=false
    while [ ! -f ${IDENTITY_JSON} ]; do
        IDENTITY_JSON_CREATED=true
        sleep 5
        $1/wigwag/pe-utils/identity-tools/generate-identity.sh \
            8081 ${IDENTITY_JSON_DIR}
    done
    if ${IDENTITY_JSON_CREATED}; then
        snapctl restart ${SNAP_INSTANCE_NAME}.edge-proxy
    fi
) 9>${LOCKFILE}
