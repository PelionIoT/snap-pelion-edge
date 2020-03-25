#!/bin/bash

# This script is used for firmware upgrades.  It checks for the existence of an
# upgrade.tar.gz file in ${SNAP_DATA}/upgrades/, and if found, untars the file
# and runs the runme.sh script inside.

# SNAP_DATA: /var/snap/pelion-edge/current/
# path copied from snap-pelion-edge/snap/hooks/install
UPGRADE_DIR="${SNAP_DATA}/upgrades"
UPGRADE_TGZ="${UPGRADE_DIR}/upgrade.tar.gz"
UPGRADE_WORKDIR=/tmp/pelion-edge-upgrade/

echo "Checking for ${UPGRADE_TGZ}"
if [ -e "${UPGRADE_TGZ}" ]; then
	#TODO: verify the firmware tarball signature & integrity
	mkdir -p "${UPGRADE_WORKDIR}"
	tar -xzf "${UPGRADE_TGZ}" -C "${UPGRADE_WORKDIR}"
	pushd "${UPGRADE_WORKDIR}"
	if [ -x runme.sh ]; then
		./runme.sh
	else
		echo "ERROR: upgrade.tar.gz did not contain runme.sh"
	fi
	popd
	# remove the file so that we don't fall into an upgrade loop
	rm "${UPGRADE_TGZ}"
	rm -rf "${UPGRADE_WORKDIR}"
fi
echo "Platform version is $(cat ${SNAP_DATA}/etc/platform_version)"
