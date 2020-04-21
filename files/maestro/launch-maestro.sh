
if [ ! -f ${SNAP_DATA}/userdata/edge_gw_identity/identity.json ]; then
    echo "identity.json does not exist"
    exit 1
fi

exec ${SNAP}/wigwag/system/bin/maestro -config $SNAP_DATA/maestro-config.yaml
