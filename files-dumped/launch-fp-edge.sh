#!/bin/bash

# SNAP_DATA: /var/snap/pelion-edge/current/
CONF_FILE=${SNAP}/fp-edge.conf

# defaults
ARGS=""

# read from CLI args given by snapcraft.yaml->apps->command
if [ "$#" -gt "0" ]; then
    ARGS="${ARGS} $@"
fi

# read from conf file
if [ -f "${CONF_FILE}" ]; then
    ARGS="${ARGS} $(cat "${CONF_FILE}")"
fi

mkdir -p ${SNAP_DATA}/userdata/edge_gw_config
jq -r .ssl.ca.ca ${SNAP}/wigwag/userdata/edge_gw_config/identity.json > ${SNAP_DATA}/userdata/edge_gw_config/ca.pem
jq -r .ssl.server.certificate ${SNAP}/wigwag/userdata/edge_gw_config/identity.json > ${SNAP_DATA}/userdata/edge_gw_config/kubelet.pem
jq -r .ssl.server.key ${SNAP}/wigwag/userdata/edge_gw_config/identity.json > ${SNAP_DATA}/userdata/edge_gw_config/kubelet-key.pem
exec ${SNAP}/wigwag/system/bin/fp-edge ${ARGS}
