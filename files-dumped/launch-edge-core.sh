#!/bin/bash

# before we do anything, call the fake bootloader
./edge-core-bootloader.sh

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

exec ${SNAP}/wigwag/mbed/edge-core ${ARGS}
