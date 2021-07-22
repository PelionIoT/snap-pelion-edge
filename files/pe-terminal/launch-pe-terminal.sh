#!/bin/bash

if [ ! -f "$SNAP_DATA/pe-terminal.conf.json" ]; then
    cp "$SNAP/pe-terminal.conf.json" "$SNAP_DATA/pe-terminal.conf.json"
fi

exec ${SNAP}/wigwag/system/bin/pe-terminal -config=$SNAP_DATA/pe-terminal.conf.json
