#!/bin/bash

# This script is used for firmware upgrades. It prepares the update
# payload for use by the fake bootloader script.
#
# The tarball signature and integrity info are handled by the update client
# before this script is called.

. $(dirname "$0")/arm_update_cmdline.sh

mkdir -p "$UPGRADE_DIR"

# copy header if present
[ -n "$HEADER" ] && cp "$HEADER" "$UPGRADE_HDR"
# copy firmware if present
[ -n "$FIRMWARE" ] && cp "$FIRMWARE" "$UPGRADE_TGZ"
