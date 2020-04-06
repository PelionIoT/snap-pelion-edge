#!/bin/bash

# This script is used for firmware upgrades. It prepares the update
# payload for use by the fake bootloader script.
#
# The tarball signature and integrity info are handled by the update client
# before this script is called.

. $(dirname "$0")/arm_update_cmdline.sh

# copy header if present
[ -n "$UPGRADE_HDR" ] && cp "$UPGRADE_HDR" "$HEADER"
