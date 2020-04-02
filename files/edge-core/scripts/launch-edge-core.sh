#!/bin/bash

# before we start edge-core, call the fake bootloader to apply any existing updates
${SNAP}/edge-core-bootloader.sh

# SNAP_DATA: /var/snap/pelion-edge/current/
CONF_FILE=${SNAP_DATA}/edge-core.conf

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

# add ${SNAP} to PATH edge-core can run the factory reset script: edge-core-factory-reset
exec env PATH=${PATH}:${SNAP} ${SNAP}/wigwag/mbed/edge-core ${ARGS}
