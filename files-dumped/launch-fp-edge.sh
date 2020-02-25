#!/bin/bash
mkdir -p ${SNAP_DATA}/userdata/edge_gw_config
jq -r .ssl.server.certificate ${SNAP_DATA}/var/lib/edge_gw_identity/identity.json > ${SNAP_DATA}/userdata/edge_gw_config/kubelet.pem
jq -r .ssl.server.key ${SNAP_DATA}/var/lib/edge_gw_identity/identity.json > ${SNAP_DATA}/userdata/edge_gw_config/kubelet-key.pem
EDGE_K8S_ADDRESS=$(jq -r .edgek8sServicesAddress ${SNAP_DATA}/var/lib/edge_gw_identity/identity.json)
GATEWAYS_ADDRESS=$(jq -r .gatewayServicesAddress ${SNAP_DATA}/var/lib/edge_gw_identity/identity.json)
EDGE_PROXY_URI_RELATIVE_PATH=$(jq -r .edge_proxy_uri_relative_path ${SNAP_DATA}/fp-edge.conf.json)

exec ${SNAP}/wigwag/system/bin/fp-edge \
    -proxy-uri=${EDGE_K8S_ADDRESS} \
    -tunnel-uri=wss://${GATEWAYS_ADDRESS#"https://"}$EDGE_PROXY_URI_RELATIVE_PATH \
    -cert-strategy=tpm \
    -cert-strategy-options=socket=/tmp/edge.sock \
    -cert-strategy-options=path=/1/pt \
    -cert-strategy-options=device-cert-name=mbed.LwM2MDeviceCert \
    -cert-strategy-options=private-key-name=mbed.LwM2MDevicePrivateKey