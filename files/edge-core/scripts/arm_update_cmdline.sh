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

# This script is used for firmware upgrades. It parses the command line in
# order to allow environment and command line parameter merging

UPGRADE_DIR="${SNAP_DATA}/upgrades"
UPGRADE_TGZ="${UPGRADE_DIR}/upgrade.tar.gz"
UPGRADE_HDR="${UPGRADE_DIR}/header.bin"
UPGRADE_INS="${UPGRADE_DIR}/installer.bin"

ACTIVE_DIR="${SNAP_DATA}/userdata/mbed"
ACTIVE_HDR="${ACTIVE_DIR}/header.bin"
ACTIVE_INS=/tmp/installer.bin

# The following variables may be provided in the environment, or overridden
# by command line arguments. See example with full set of scripts in
# mbed-edge/lib/mbed-cloud-client/update-client-hub/modules/pal-linux/scripts/generic/
#
# HEADER
# FIRMWARE
# LOCATION
# OFFSET
# SIZE

while [ -n "$1" ]; do
    shift_count=2
    case "$1" in
        -h|--header)
            HEADER="$2"
            ;;
        -f|--firmware)
            FIRMWARE="$2"
            ;;
        -l|--location)
            LOCATION="$2"
            ;;
        -o|--offset)
            OFFSET="$2"
            ;;
        -s|--size)
            SIZE="$2"
            ;;
        -*)
            echo >&2 "Unknown option: $1"
            shift_count=1
            ;;
        *)
            # the script can be called from pal_ext_imageActivationWorker()
            # with a single argument: the firmware path
            FIRMWARE="$1"
            shift_count=1
            ;;
    esac
    shift $shift_count
done

LOCATION=${LOCATION:-0}
OFFSET=${OFFSET:-0}
SIZE=${SIZE:-0}
