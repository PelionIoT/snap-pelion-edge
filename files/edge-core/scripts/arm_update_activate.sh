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

# This script is used for firmware upgrades. It prepares the update
# payload for use by the fake bootloader script.
#
# The tarball signature and integrity info are handled by the update client
# before this script is called.

. $(dirname "$0")/arm_update_cmdline.sh

mkdir -p "$UPGRADE_DIR"

# copy header to location to be applied by bootloader
[ -n "$HEADER" ] && cp "$HEADER" "$UPGRADE_HDR"
# copy firmware to location to be applied by bootloader
[ -n "$FIRMWARE" ] && cp "$FIRMWARE" "$UPGRADE_TGZ"
# create fake installer.bin until we figure out if it's needed for anything
# the size originates from struct _arm_uc_installer_details_t in arm_uc_types.h
# see https://github.com/ARMmbed/mbed-edge/blob/master/lib/mbed-cloud-client/update-client-hub/modules/common/update-client-common/arm_uc_types.h#L74
dd if=/dev/zero of=$UPGRADE_INS bs=68 count=1
