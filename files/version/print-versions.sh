#!/bin/bash

THISFILE=$(basename $0)
if [[ -e "${SNAP_DATA}/$THISFILE" ]] && [[ "$0" != "${SNAP_DATA}/$THISFILE" ]]; then
    exec ${SNAP_DATA}/$THISFILE $@
fi

SHOW_DOCKER="false"

while [ -n "$1" ]; do
	case "$1" in
	--all) SHOW_DOCKER="true";;
	*) echo "$1 not supported";;
	esac
	shift
done

echo "relay-term: unsupported"
echo -n "pe-utils: "; ${SNAP}/wigwag/pe-utils/identity-tools/developer_identity/create-dev-identity.sh -V
echo -n "edge-core: "; ${SNAP}/wigwag/mbed/edge-core --version
echo -n "devicedb: "; ${SNAP}/wigwag/system/bin/devicedb -version
echo -n "maestro: "; ${SNAP}/wigwag/system/bin/maestro --version
echo -n "maestro-shell: "; ${SNAP}/wigwag/system/bin/maestro-shell -h | grep ver
echo "edge-proxy: unsupported"
echo -n "kubelet: "; ${SNAP}/wigwag/system/bin/kubelet --version
if [ "${SHOW_DOCKER}" = "true" ]; then
	echo -n "docker: "; ${SNAP}/bin/docker --version
	echo -n "docker-runc: "; ${SNAP}/bin/docker-runc --version
	echo -n "docker-containerd: "; ${SNAP}/bin/docker-containerd --version
	echo -n "docker-init: "; ${SNAP}/bin/docker-init --version
fi
