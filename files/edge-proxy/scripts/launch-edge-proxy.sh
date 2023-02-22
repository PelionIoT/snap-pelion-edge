#!/bin/bash
# ----------------------------------------------------------------------------
# Copyright (c) 2020, Arm Limited and affiliates.
# Copyright (c) 2023, Izuma Networks
#
# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ----------------------------------------------------------------------------

if [ ! -f "$SNAP_DATA/edge-proxy.conf.json" ]; then
    cp "$SNAP/edge-proxy.conf.json" "$SNAP_DATA/edge-proxy.conf.json"
fi

EDGE_K8S_ADDRESS=$(jq -r .edgek8sServicesAddress "${SNAP_DATA}/userdata/edge_gw_identity/identity.json")
GATEWAYS_ADDRESS=$(jq -r .gatewayServicesAddress "${SNAP_DATA}/userdata/edge_gw_identity/identity.json")
CONTAINERS_ADDRESS=$(jq -r .containerServicesAddress "${SNAP_DATA}/userdata/edge_gw_identity/identity.json")
DEVICE_ID=$(jq -r .deviceID "${SNAP_DATA}/userdata/edge_gw_identity/identity.json")
EDGE_PROXY_URI_RELATIVE_PATH=$(jq -r .edge_proxy_uri_relative_path "${SNAP_DATA}/edge-proxy.conf.json")

if ! grep -q "gateways.local" /etc/hosts; then
    echo "127.0.0.1 gateways.local" >> /etc/hosts
fi

if ! grep -q "containers.local" /etc/hosts; then
    echo "127.0.0.1 containers.local" >> /etc/hosts
fi

if ! grep -q "$DEVICE_ID" /etc/hosts; then
    echo "127.0.0.1 $DEVICE_ID" >> /etc/hosts
fi

EXTERN_HTTP_PROXY=$(snapctl get edge-proxy.extern-http-proxy-uri)
if [[ "$EXTERN_HTTP_PROXY" = "" ]]; then
    EXTERN_ARG=
else
    EXTERN_ARG=-extern-http-proxy-uri=$EXTERN_HTTP_PROXY
fi

EXTERN_HTTP_PROXY_CACERT=$(snapctl get edge-proxy.extern-http-proxy-cacert)
if [[ "$EXTERN_HTTP_PROXY_CACERT" = "" ]]; then
    EXTERN_CACERT_ARG=
else
    EXTERN_CACERT_ARG=-extern-http-proxy-cacert=$EXTERN_HTTP_PROXY_CACERT
fi

HTTP_TUNNEL="$(snapctl get edge-proxy.http-tunnel-listen)"
if [[ "${HTTP_TUNNEL}" = "" ]]; then
    HTTP_TUNNEL_ARGS=
else
    HTTP_TUNNEL_ARGS="-http-tunnel-listen=${HTTP_TUNNEL}"
fi

HTTPS_TUNNEL="$(snapctl get edge-proxy.https-tunnel-listen)"
if [[ "${HTTPS_TUNNEL}" = "" ]]; then
    HTTPS_TUNNEL_ARGS=
else
    HTTPS_TUNNEL_ARGS="-https-tunnel-listen=${HTTPS_TUNNEL}"

    CERT=$(snapctl get edge-proxy.https-tunnel-tls-cert)
    if [ -n "${CERT}" ]; then
        HTTPS_TUNNEL_ARGS="${HTTPS_TUNNEL_ARGS} -https-tunnel-tls-cert=${CERT}"
    fi

    KEY=$(snapctl get edge-proxy.https-tunnel-tls-key)
    if [ -n "${KEY}" ]; then
        HTTPS_TUNNEL_ARGS="${HTTPS_TUNNEL_ARGS} -https-tunnel-tls-key=${KEY}"
    fi

    USER=$(snapctl get edge-proxy.https-tunnel-username)
    if [ -n "${USER}" ]; then
        HTTPS_TUNNEL_ARGS="${HTTPS_TUNNEL_ARGS} -https-tunnel-username=${USER}"
    fi

    PASS=$(snapctl get edge-proxy.https-tunnel-password)
    if [ -n "${PASS}" ]; then
        HTTPS_TUNNEL_ARGS="${HTTPS_TUNNEL_ARGS} -https-tunnel-password=${PASS}"
    fi
fi

if [[ $(snapctl get edge-proxy.debug) = "false" ]]; then
    echo "edge-proxy logging is disabled.  To see logs, run \"snap set ${SNAP_INSTANCE_NAME} edge-proxy.debug=true\" and restart edge-proxy"
    # this is known as bash exec redirection.
    # see https://www.tldp.org/LDP/abs/html/x17974.html
    exec >/dev/null 2>&1
fi

exec "${SNAP}/wigwag/system/bin/edge-proxy" \
    -proxy-uri="${EDGE_K8S_ADDRESS}" \
    -tunnel-uri="ws://gateways.local$EDGE_PROXY_URI_RELATIVE_PATH" \
    -cert-strategy=tpm \
    -cert-strategy-options=socket=/tmp/edge.sock \
    -cert-strategy-options=path=/1/pt \
    -cert-strategy-options=device-cert-name=mbed.LwM2MDeviceCert \
    -cert-strategy-options=private-key-name=mbed.LwM2MDevicePrivateKey \
    "${EXTERN_ARG}" \
    "${EXTERN_CACERT_ARG}" \
    "${HTTP_TUNNEL_ARGS}" \
    "${HTTPS_TUNNEL_ARGS}" \
    -forwarding-addresses={\"gateways.local\":\"${GATEWAYS_ADDRESS#"https://"}\"\,\"containers.local\":\"${CONTAINERS_ADDRESS#"https://"}\"}
