#!/bin/bash

# This script is used for firmware upgrades. It prepares the update
# payload for use by the fake bootloader script.
#
# The tarball signature and integrity info are handled by the update client
# before this script is called.

# SNAP_DATA: /var/snap/pelion-edge/current/
# path copied from snap-pelion-edge/snap/hooks/install
UPGRADE_DIR="${SNAP_DATA}/upgrades"
UPGRADE_TGZ="${UPGRADE_DIR}/upgrade.tar.gz"
UPGRADE_HDR="${UPGRADE_DIR}/header.bin"

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

mkdir -p "$UPGRADE_DIR"

# copy header if present
[ -n "$HEADER" ] && cp "$HEADER" "$UPGRADE_HDR"
# copy firmware if present
[ -n "$FIRMWARE" ] && cp "$FIRMWARE" "$UPGRADE_TGZ"
