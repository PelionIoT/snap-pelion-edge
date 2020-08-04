
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
    cp "$SNAP/wigwag/wwrelay-utils/conf/maestro-conf/edge-config-dell5000-demo.yaml" "$SNAP_DATA/maestro-config.yaml"
fi

exec ${SNAP}/wigwag/system/bin/maestro -config $SNAP_DATA/maestro-config.yaml
