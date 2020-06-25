
DEVICE_ID=`jq -r .deviceID ${SNAP_DATA}/userdata/edge_gw_identity/identity.json`
if [ $? -ne 0 ]; then
    echo "Unable to extract device ID from identity.json"
    exit 1
fi

${SNAP}/launch-edgenet.sh
if [ $? -ne 0 ]; then
    echo "Unable to create edgenet docker network"
    exit 2
fi

# Get the IP address of the interface with Internet access
IP_ADDR=$(ip route get 1.1.1.1 | grep -oP 'src \K\S+')

if [ -n $IP_ADDR ]; then
    NODE_IP_OPTION="--node-ip=$(IP_ADDR)"
else
    NODE_IP_OPTION=""
fi

exec ${SNAP}/wigwag/system/bin/kubelet \
    --root-dir=${SNAP_COMMON}/var/lib/kubelet \
    --offline-cache-path=${SNAP_COMMON}/var/lib/kubelet/store \
    --fail-swap-on=false \
    --image-pull-progress-deadline=2m \
    --hostname-override=${DEVICE_ID} \
    --kubeconfig=${SNAP}/wigwag/system/var/lib/kubelet/kubeconfig \
    --cni-bin-dir=${SNAP}/wigwag/system/opt/cni/bin \
    --cni-conf-dir=${SNAP}/wigwag/system/etc/cni/net.d \
    --network-plugin=cni \
    --register-node=true \
    $NODE_IP_OPTION
