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

echo -n "relay-term: "; cat ${SNAP}/wigwag/etc/edge-node-modules.VERSION
echo -n "pe-utils: "; ${SNAP}/wigwag/pe-utils/identity-tools/developer_identity/create-dev-identity.sh -V
echo -n "edge-core: "; ${SNAP}/wigwag/mbed/edge-core --version
echo -n "devicedb: "; ${SNAP}/wigwag/system/bin/devicedb -version
echo -n "maestro: "; ${SNAP}/wigwag/system/bin/maestro --version
echo -n "maestro-shell: "; cat ${SNAP}/wigwag/etc/maestro-shell.VERSION
echo -n "edge-proxy: "; cat ${SNAP}/wigwag/etc/edge-proxy.VERSION
echo -n "kubelet: "; ${SNAP}/wigwag/system/bin/kubelet --version | cut -d' ' -f2
if [ "${SHOW_DOCKER}" = "true" ]; then
	echo -n "docker: "; ${SNAP}/bin/docker --version
	echo -n "docker-runc: "; ${SNAP}/bin/docker-runc --version
	echo -n "docker-containerd: "; ${SNAP}/bin/docker-containerd --version
	echo -n "docker-init: "; ${SNAP}/bin/docker-init --version
fi
