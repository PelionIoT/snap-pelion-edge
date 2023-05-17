#!/bin/bash

SHOW_DOCKER="false"

while [ -n "$1" ]; do
    case "$1" in
    --all) SHOW_DOCKER="true";;
    *) echo "$1 not supported";;
    esac
    shift
done

echo -n "snap-pelion-edge: "; jq -r ".version" < "${SNAP}/edge/versions.json"
echo -n "edge-core: "; "${SNAP}/wigwag/mbed/edge-core" --version
echo -n "pe-terminal: "; cat "${SNAP}/edge/pe-terminal.VERSION"
echo -n "pe-utils: "; cat "${SNAP}/edge/pe-utils.VERSION"
echo -n "edge-info: "; cat "${SNAP}/edge/edge-info.VERSION"
echo -n "edge-testnet: "; cat "${SNAP}/edge/edge-testnet.VERSION"
echo -n "maestro: "; cat "${SNAP}/edge/maestro.VERSION"
echo -n "edge-proxy: "; cat "${SNAP}/edge/edge-proxy.VERSION"
echo -n "kubelet: "; "${SNAP}/wigwag/system/bin/kubelet" --version | cut -d' ' -f2
echo -n "bouncer: "; cat "${SNAP}/edge/bouncer.VERSION"
echo -n "cosign: "; cat "${SNAP}/edge/cosign.VERSION"
if [ "${SHOW_DOCKER}" = "true" ]; then
    echo -n "docker: "; "${SNAP}/bin/docker" --version
    echo -n "docker-runc: "; "${SNAP}/bin/docker-runc" --version
    echo -n "docker-containerd: "; "${SNAP}/bin/docker-containerd" --version
    echo -n "docker-init: "; "${SNAP}/bin/docker-init" --version
fi
