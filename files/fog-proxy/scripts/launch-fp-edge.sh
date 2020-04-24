#!/bin/bash
EDGE_K8S_ADDRESS=$(jq -r .edgek8sServicesAddress ${SNAP_DATA}/userdata/edge_gw_identity/identity.json)
GATEWAYS_ADDRESS=$(jq -r .gatewayServicesAddress ${SNAP_DATA}/userdata/edge_gw_identity/identity.json)
EDGE_PROXY_URI_RELATIVE_PATH=$(jq -r .edge_proxy_uri_relative_path ${SNAP_DATA}/fp-edge.conf.json)
if ! grep -q "gateways.local" /etc/hosts; then
    echo "127.0.0.1 gateways.local" >> /etc/hosts
fi
exec ${SNAP}/wigwag/system/bin/fp-edge \
    -proxy-uri=${EDGE_K8S_ADDRESS} \
    -tunnel-uri=ws://gateways.local$EDGE_PROXY_URI_RELATIVE_PATH \
    -cert-strategy=tpm \
    -cert-strategy-options=socket=/tmp/edge.sock \
    -cert-strategy-options=path=/1/pt \
    -cert-strategy-options=device-cert-name=mbed.LwM2MDeviceCert \
    -cert-strategy-options=private-key-name=mbed.LwM2MDevicePrivateKey \
    -forwarding-addresses={\"gateways.local\":\"${GATEWAYS_ADDRESS#"https://"}\"}
ls
