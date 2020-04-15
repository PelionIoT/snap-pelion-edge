#!/bin/bash

# This script is used for firmware upgrades. It parses the command line in
# order to allow environment and command line parameter merging

# SNAP_DATA: /var/snap/pelion-edge/current/
# path copied from snap-pelion-edge/snap/hooks/install
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
