#!/bin/bash
mkdir -p ${SNAP_DATA}/userdata/edge_gw_config
jq -r .ssl.server.certificate ${SNAP_DATA}/var/lib/edge_gw_identity/identity.json > ${SNAP_DATA}/userdata/edge_gw_config/kubelet.pem
jq -r .ssl.server.key ${SNAP_DATA}/var/lib/edge_gw_identity/identity.json > ${SNAP_DATA}/userdata/edge_gw_config/kubelet-key.pem

exec ${SNAP}/wigwag/system/bin/fp-edge \
    -proxy-uri=https://kaas-edge-nodes.arm.com \
    -ca=${SNAP}/ca.pem \
    -cert-strategy-options=cert=${SNAP_DATA}/userdata/edge_gw_config/kubelet.pem \
    -cert-strategy-options=key=${SNAP_DATA}/userdata/edge_gw_config/kubelet-key.pem \
    -tunnel-uri=ws://127.0.0.1:8080/connect
