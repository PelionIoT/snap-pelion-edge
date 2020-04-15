#!/bin/bash
#
# This script will be run on FOTA execution
#
# You can update/install other snaps or update pelion-edge itself.
#
# If you update the pelion-edge snap, make sure it is the LAST step,
# since that will stop the current pelion-edge snap (including this
# script) and prevent it from running anything else (or returning to its
# caller).
#

set -eux

echo "START runme.sh"
snap install --devmode pelion-edge_1.0_amd64.snap
echo "END runme.sh"
