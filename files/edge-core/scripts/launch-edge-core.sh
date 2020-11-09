#!/bin/bash
# ----------------------------------------------------------------------------
# Copyright (c) 2020, Arm Limited and affiliates.
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

export PLATFORM_VERSION=${SNAP_DATA}/etc/platform_version
export READABLE_VERSION=${SNAP_DATA}/etc/readable_version
export VERSION_MAP=${SNAP_DATA}/etc/version_map.json

# make sure the PAL_FS_MOUNT_POINT_PRIMARY directory exists so it can be populated
# with mcc_config
if [ ! -d ${SNAP_DATA}/userdata/mbed ]; then
    mkdir -p ${SNAP_DATA}/userdata/mbed
fi

# make sure the upgrade folder exists in case we need to download updates
if [ ! -d "$SNAP_DATA/upgrades" ]; then
    mkdir -p $SNAP_DATA/upgrades
fi

# before we start edge-core, call the fake bootloader to apply any existing updates
${SNAP}/edge-core-bootloader.sh

function map_version() {
    HASH_VER=$1
    READABLE=""
    if [ -f $VERSION_MAP ]; then
        READABLE=$(cat $VERSION_MAP | jq -r ".\"${HASH_VER}\"")
        if [ "$READABLE" == "null" ]; then
           READABLE=""
        fi
    fi
    echo $READABLE
}

# Use the platform version script to generate a new MD5 hash
# The platform version file is read by edge-core and populates LWM2M /10252/0/11
PLAT_VER=$(${SNAP}/bin/platform-version.sh)
echo $PLAT_VER > $PLATFORM_VERSION
# Map platform version to human readable version string
# The readable version file is read by edge-core and populates LWM2M /10252/0/10
READ_VER=$(map_version $PLAT_VER)
echo $READ_VER > $READABLE_VERSION


CONF_FILE=${SNAP_DATA}/edge-core.conf
if [ ! -f "${CONF_FILE}" ]; then
    cp "$SNAP/edge-core.conf" "${CONF_FILE}"
fi

# defaults
ARGS=""

# read from CLI args given by snapcraft.yaml->apps->command
if [ "$#" -gt "0" ]; then
    ARGS="${ARGS} $@"
fi

# read from conf file
if [ -f "${CONF_FILE}" ]; then
    ARGS="${ARGS} $(cat "${CONF_FILE}")"
fi

# add ${SNAP} to PATH edge-core can run the factory reset script: edge-core-factory-reset
exec env PATH=${PATH}:${SNAP} ${SNAP}/wigwag/mbed/edge-core ${ARGS}
