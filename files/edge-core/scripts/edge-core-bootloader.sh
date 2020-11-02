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

# This script is used for firmware upgrades.  It checks for the existence of an
# upgrade.tar.gz file in ${SNAP_DATA}/upgrades/, and if found, untars the file
# and runs the runme.sh script inside.

UPGRADE_DIR=${SNAP_DATA}/upgrades
UPGRADE_TGZ=${UPGRADE_DIR}/upgrade.tar.gz
UPGRADE_HDR=${UPGRADE_DIR}/header.bin
UPGRADE_VER=${UPGRADE_DIR}/platform_version
UPGRADE_WORKDIR=/tmp/pelion-edge-upgrade/
ACTIVE_HDR=${SNAP_DATA}/userdata/mbed/header.bin
ACTIVE_VER=${SNAP_DATA}/etc/platform_version

function log_msg()
{
	echo "$@" |  systemd-cat -p info -t "EDGE-CORE-Bootloader"
}

function try_upgrade()
{
	let retval=0
	echo "Checking for ${UPGRADE_TGZ}"
	if [ -e "${UPGRADE_TGZ}" ]; then
		mkdir -p "${UPGRADE_WORKDIR}"
		tar --no-same-owner -xzf "${UPGRADE_TGZ}" -C "${UPGRADE_WORKDIR}"
		# remove the upgrade tgz file so that we don't fall into an upgrade loop
		rm "${UPGRADE_TGZ}"
		pushd "${UPGRADE_WORKDIR}"
		# copy the new version file to the upgrade folder to be copied
		# into its final destination after the upgrade finishes
		if [ -e platform_version ]; then
			cp platform_version "${UPGRADE_VER}"
			if [ -x runme.sh ]; then
				echo "edge-core-bootloader.sh: Running runme.sh" | systemd-cat -p info -t FOTA
				./runme.sh 2>&1 | systemd-cat -p info -t FOTA
				retval=$?
			else
				echo "ERROR: upgrade.tar.gz did not contain runme.sh"
				retval=1
			fi
		else
			echo "ERROR: upgrade.tar.gz did not contain platform_version"
			retval=1
		fi
		popd
	fi
	return $retval
}

# if a snap refresh is in progress, wait until it is done
# returns: 0 if the snap refresh completed successfully
#          1 if there is no watch id
#          2 if the snap refresh completed with error
#          3 if the snap refresh did not finish on time (timed out)
WATCH_ID_STATUS_SUCCESS=0
WATCH_ID_STATUS_NONE=1
WATCH_ID_STATUS_ERROR=2
WATCH_ID_STATUS_TIMEOUT=3
function check_snap_refresh() {
	local watch_id_file=$SNAP_COMMON/refresh_watch_id
	local timestamp=$(date +%s)
	local timeout=$(snapctl get edge-core.refresh-timeout)
	local tdiff=0
	local retval=$WATCH_ID_STATUS_NONE
	if [ -f "$watch_id_file" ]; then
		retval=$WATCH_ID_STATUS_TIMEOUT
		watch_id=$(cat "$watch_id_file")
		log_msg "Waiting for snap refresh ID $watch_id, max $timeout seconds"
		local end_msg="did not complete in time"
		while [ $tdiff -lt $timeout ]; do
			status=$(curl -sS --unix-socket /run/snapd.socket http://localhost/v2/changes/$watch_id | jq .result.status)
			[ "$status" = "Done" ] && {
				retval=$WATCH_ID_STATUS_SUCCESS
				end_msg="completed successfully"
				break
			}
			[ "$status" = "Error" ] && {
				retval=$WATCH_ID_STATUS_ERROR
				end_msg="finished with error"
				break
			}
			sleep 1
			tdiff=$(($(date +%s) - timestamp))
		done
		log_msg "Snap refresh $end_msg"
		rm "$watch_id_file" 2>/dev/null
	else
		log_msg "No snap refresh in progress, starting edge-core"
	fi
	return $retval
}

# If the upgrade fails for any reason, we ignore the new user version string
try_upgrade || rm -f "${UPGRADE_VER}"

check_snap_refresh
# suggested usage: check_snap_refresh && copy_hdr_bin

if [ -e "${UPGRADE_HDR}" ]; then
	# copy the firmware header to persistent storage for later
	# use by the arm_update_active_details.sh script
	echo "Moving the new firmware header to persistent storage ${ACTIVE_HDR}"
	mv "${UPGRADE_HDR}" "${ACTIVE_HDR}"
fi

if [ -e "${UPGRADE_VER}" ]; then
	echo "Moving the new firmware version file to final location ${ACTIVE_VER}"
	mv "${UPGRADE_VER}" "${ACTIVE_VER}"
fi

if [ -d "${UPGRADE_WORKDIR}" ]; then
	echo "Deleting the upgrade workdir ${UPGRADE_WORKDIR}"
	rm -rf "${UPGRADE_WORKDIR}"
fi

# return success to allow edge-core to continue booting
exit 0
