#!/bin/bash

if [ ! -f ${SNAP_DATA}/userdata/edge_gw_identity/identity.json ]; then
    echo "identity.json does not exist"
    exit 1
fi

if [ ! -d "$SNAP_DATA/wigwag/log" ]; then
    mkdir -p $SNAP_DATA/wigwag/log
fi

if [ ! -d "$SNAP_DATA/userdata/etc" ]; then
    mkdir -p $SNAP_DATA/userdata/etc
fi

if [ ! -f "$SNAP_DATA/maestro-config.yaml" ]; then
    cp "$SNAP/wigwag/wwrelay-utils/conf/maestro-conf/maestro-config-dell5000.yaml" "$SNAP_DATA/maestro-config.yaml"
fi

config_file=$SNAP_DATA/maestro-config.yaml

networking_disabled=$($SNAP/bin/yq r $config_file network.disable)

if [ "$networking_disabled" != "true" ]; then

	# Obtain interfaces maestro is managing
	interfaces=$($SNAP/bin/yq r $config_file network.interfaces.*.if_name)

	# If interfaces found, turn of nmcli management of said interfaces
	[ $? = 0 ] && for i in $interfaces; do
	    $SNAP/bin/nmcli dev set $i managed no
	done

	# @todo: turn on management of previous interfaces that were disabled
	#        and are no longer managed by maestro

fi

exec ${SNAP}/wigwag/system/bin/maestro -config $SNAP_DATA/maestro-config.yaml
