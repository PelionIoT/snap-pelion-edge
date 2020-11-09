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
# upgrade.tar.gz file in ${SNAP_DATA}/upgrades/, and if found, untars it and
# runs through the upgrade procedure.

UPGRADE_DIR=${SNAP_DATA}/upgrades
UPGRADE_TGZ=${UPGRADE_DIR}/upgrade.tar.gz
UPGRADE_HDR=${UPGRADE_DIR}/header.bin
UPGRADE_WORKDIR=${SNAP_COMMON}/pelion-edge-upgrade
UPGRADE_WORKDIR_FAILED=${SNAP_COMMON}/pelion-edge-upgrade-failed
PLATFORM_MD5=${UPGRADE_WORKDIR}/platform-version.md5
ACTIVE_HDR=${SNAP_DATA}/userdata/mbed/header.bin
REFRESH_WATCHID=${SNAP_COMMON}/refresh_watch_id

function log_msg()
{
	echo "$@" |  systemd-cat -p info -t "EDGE-CORE-Bootloader"
}

function snap_refresh() {
    if [ -e "${REFRESH_WATCHID}" ]; then
        echo "Snap refresh already in progress..."
        return 0
    else
        response=$(curl -sS -H "Content-Type: application/json" --unix-socket /run/snapd.socket http://localhost/v2/snaps -X POST -d '{ "action": "refresh" }')
        status=$(echo $response | jq -r '.status')
        if [ "$status" = "Accepted" ]; then
            change_id=$(echo $response | jq -r '.change')
            echo $change_id > $REFRESH_WATCHID
            return 0
        else
            echo "Attempted snap refresh.  Returned status " $status
            echo "Complete response: " $response
            return 1
        fi
    fi
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
			status=$(curl -sS --unix-socket /run/snapd.socket http://localhost/v2/changes/$watch_id | jq -r .result.status)
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

echo "Checking for ${UPGRADE_TGZ}"
if [ -e "${UPGRADE_TGZ}" ]; then
    if [ -e "${UPGRADE_WORKDIR}" ]; then
        echo "Deleting old upgrade workdir..."
        rm -rf "${UPGRADE_WORKDIR}"
    fi
    echo "Unpacking ${UPGRADE_TGZ} to ${UPGRADE_WORKDIR}..."
    mkdir -p "${UPGRADE_WORKDIR}"
    tar --no-same-owner -xzf "${UPGRADE_TGZ}" -C "${UPGRADE_WORKDIR}"
    # remove the upgrade tgz file so that we don't fall into an upgrade loop
    rm "${UPGRADE_TGZ}"
else
    echo "No upgrade payload found...continue to look for upgrade in progress"
fi

function check_error() {
    if [ $2 != 0 ]; then
        echo "$1 failed: $2"
        rm -rf "${UPGRADE_WORKDIR_FAILED}"
        mv "${UPGRADE_WORKDIR}" "${UPGRADE_WORKDIR_FAILED}"
        exit $3
    fi
}

# move into folder and call pre-refresh if exists
if [ -e "${UPGRADE_WORKDIR}" ]; then
    echo "Processing upgrade..."
    pushd "${UPGRADE_WORKDIR}"

    if [ -x pre-refresh.sh ]; then
        echo "edge-core-bootloader.sh: Running pre-refresh.sh" | systemd-cat -p info -t FOTA-PRE-REFRESH
        ./pre-refresh.sh 2>&1 | systemd-cat -p info -t FOTA-PRE-REFRESH
        check_error "pre-refresh" $? 1
        rm pre-refresh.sh
    fi
    if [ -f map-version.json ]; then
        echo "Adding new version mappings"
        cp map-version.json ${VERSION_MAP}
    fi

    snap_refresh
    check_error "snap_refresh" $? 2

    # this blocks until snap refresh is complete
    check_snap_refresh
    check_error "check_snap_refresh" $? 3

    # after snap refresh completes, compare the expected hash values
    if [ "$(cat ${PLATFORM_MD5})" != "$(${SNAP}/bin/platform-version.sh)" ]; then
        check_error "hash check" 1 4
    fi

    # now that we're certain the system is in an expected state, call post-refresh.sh if it exists
    if [ -x post-refresh.sh ]; then
        echo "edge-core-bootloader.sh: Running post-refresh.sh" | systemd-cat -p info -t FOTA-POST-REFRESH
        ./post-refresh.sh 2>&1 | systemd-cat -p info -t FOTA-POST-REFRESH
        check_error "post-refresh" $? 5
        rm post-refresh.sh
    fi

    # copy the header.bin into place if all previous steps succeed
    echo "Moving the new firmware header to persistent storage ${ACTIVE_HDR}"
    mv "${UPGRADE_HDR}" "${ACTIVE_HDR}"

    # delete the upgrade workdir only after snap-refresh is complete
    # and post-refresh.sh is finished
    echo "Deleting the upgrade workdir ${UPGRADE_WORKDIR}"
    rm -rf "${UPGRADE_WORKDIR}" "${UPGRADE_WORKDIR_FAILED}"

    popd
    echo "Done processing upgrade"
else
    echo "No upgrade in progress...continue to boot"
fi

# return success to allow edge-core to continue booting
exit 0
