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
# make sure this matches the build-time option PAL_FS_MOUNT_POINT_PRIMARY in cmake/target.cmake
export EDGE_CORE_CREDENTIALS_DIR=${SNAP_DATA}/userdata/mbed/mcc_config
export DEVICE_CBOR="${SNAP_COMMON}/device.cbor"

if [ -e /tmp/factory-reset-in-progress ]; then
    echo "edge-core refusing to start, factory reset in progress.  To complete the reset, reboot the device."
    exit 0
fi

# make sure the PAL_FS_MOUNT_POINT_PRIMARY directory exists so it can be populated
# with mcc_config
edge_core_credentials_parent_dir=$(dirname ${EDGE_CORE_CREDENTIALS_DIR})
if [ ! -d ${edge_core_credentials_parent_dir} ]; then
    mkdir -m 700 -p ${edge_core_credentials_parent_dir}
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

# add conf from the environment
EXTERN_HTTP_PROXY=$(snapctl get edge-core.proxy)
if [[ -n "$EXTERN_HTTP_PROXY" ]]; then
    ARGS="${ARGS} -x ${EXTERN_HTTP_PROXY}"
fi

# Here we determine which mode to boot: factory, developer, or byoc mode.
# To do that, we first check the configured mode. If the user configured
# a specific mode then boot in that mode, else check if we are already
# provisioned (i.e., we have a populated mcc_config/WORKING/ folder) and
# if so then boot factory mode under the assumption that it shouldn't
# matter how the mcc_config folder was created as factory mode should
# still be able to use it to register.  If we're not provisioned, attempt
# to find byoc credentials and finally dev credentials on disk.
edge_core=""
mode=$(snapctl get edge-core.provision-mode)
case "$mode" in
factory)
    echo "edge-core provisioning is set to factory mode"
    edge_core=${SNAP}/wigwag/mbed/edge-core
    ;;
developer)
    echo "edge-core provisioning is set to developer mode"
    edge_core=${SNAP}/wigwag/mbed/edge-core-dev
    if [ ! -x ${edge_core} ]; then
        echo "ERROR: edge-core.provision-mode set to developer, but no developer binary is installed"
        edge_core=""
    fi
    ;;
byoc)
    echo "edge-core provisioning is set to byoc mode"
    edge_core=${SNAP}/wigwag/mbed/edge-core-byoc
    if [ -x ${edge_core} ]; then
        ARGS="${ARGS} --cbor-conf ${DEVICE_CBOR}"
    else
        echo "ERROR: edge-core.provision-mode set to byoc, but no byoc binary is installed"
        edge_core=""
    fi
    ;;
*)
    if [ ! "$mode" = "auto" ]; then
        echo "ERROR: unsupported edge-core provision-mode \"${mode}\", falling back to auto"
    fi
    echo "edge-core provisioning is set to auto mode"
    if [ ! $(ls -A ${EDGE_CORE_CREDENTIALS_DIR}/WORKING/ | wc -l) -eq 0 ]; then
        echo "edge-core is provisioned, booting in factory mode"
        edge_core=${SNAP}/wigwag/mbed/edge-core
    else
        echo "edge-core is not provisioned, checking for CBOR file ${DEVICE_CBOR}"
        if [ -f ${DEVICE_CBOR} ]; then
            echo "found CBOR file, checking for edge-core-byoc binary"
            edge_core=${SNAP}/wigwag/mbed/edge-core-byoc
            if [ -x ${edge_core} ]; then
                echo "found CBOR file and edge-core-byoc, booting byoc mode"
                ARGS="${ARGS} --cbor-conf ${DEVICE_CBOR}"
            else
                echo "WARNING: found CBOR file, but no byoc binary is installed. checking developer mode."
                edge_core=""
            fi
        else
            echo "CBOR file not found, checking if the snap was built with developer mode"
        fi
        if [ -z ${edge_core} ]; then
            if [ -x ${SNAP}/wigwag/mbed/edge-core-dev ]; then
                echo "developer mode binary found, booting developer mode"
                edge_core=${SNAP}/wigwag/mbed/edge-core-dev
            else
                echo "developer mode binary not found"
            fi
        fi
    fi
    ;;
esac
if [ -z "$edge_core" ]; then
    # couldn't find mcc_config credentials, BYOC credentials, or dev credentials and
    # the user didn't specify a mode.
    echo "ERROR: device is not provisioned with edge credentials. aborting"
    exit 1
fi

# add ${SNAP} to PATH edge-core can run the factory reset script: edge-core-factory-reset
exec env PATH=${PATH}:${SNAP} ${edge_core} ${ARGS}
