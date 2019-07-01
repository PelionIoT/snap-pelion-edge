#!/bin/bash

# SNAP_DATA: /var/snap/pelion-edge/current/
CONF_FILE=${SNAP_DATA}/edge-core.conf

ARGS=""
if [ -f "${CONF_FILE}" ]; then
    ARGS=$(cat "${CONF_FILE}")
fi

exec ${SNAP}/edge-core ${ARGS}
