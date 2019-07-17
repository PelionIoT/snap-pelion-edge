#!/bin/bash

# SNAP_DATA: /var/snap/pelion-edge/current/
CONF_FILE=${SNAP_DATA}/fp-edge.conf

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

mkdir -p /userdata/edge_gw_config
jq -r .ssl.ca.ca /userdata/edge_gw_config/identity.json > /userdata/edge_gw_config/ca.pem
jq -r .ssl.server.certificate /userdata/edge_gw_config/identity.json > /userdata/edge_gw_config/kubelet.pem
jq -r .ssl.server.key userdata/edge_gw_config/identity.json > /userdata/edge_gw_config/kubelet-key.pem
exec ${SNAP}/wigwag/system/bin/fp-edge ${ARGS}
