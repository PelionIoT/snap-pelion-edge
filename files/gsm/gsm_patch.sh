#!/bin/bash

set -euf -o pipefail

mmcli -L | grep "No modems were found" && { echo "no modems found so exiting"; exit 0; }

# ensure modem manager is in debug mode so we can send AT commands to it
# https://www.freedesktop.org/software/ModemManager/man/1.0.0/mmcli.8.html
DENABLE=$(curl -sS -H "Content-Type: application/json" --unix-socket /run/snapd.socket http://localhost/v2/snaps/modem-manager/conf -X GET | jq .result.debug.enable)
if [ "${DENABLE}" != "true" ]; then
    curl -sS -H "Content-Type: application/json" --unix-socket /run/snapd.socket http://localhost/v2/snaps/modem-manager/conf -X PUT -d '{ "debug.enable": "true" }'
    curl -sS -H "Content-Type: application/json" --unix-socket /run/snapd.socket http://localhost/v2/apps -X POST -d '{ "action": "restart", "names": [ "modem-manager" ] }'
    sleep 60
fi

while true; do
    if mmcli -m 0 --command='AT+CGDCONT?' | grep -q attach.telus.com; then
        # we're in purgatory
        # Remove any wwan0 (gsm) profiles from network manager
        nmcli c show | grep "  gsm    " | awk '{ print $1 }' | xargs -r nmcli c delete
        # Restart modem manager snap
        curl -sS -H "Content-Type: application/json" --unix-socket /run/snapd.socket http://localhost/v2/apps -X POST -d '{ "action": "restart", "names": [ "modem-manager" ] }'
        # Modify ACT setting
        mmcli -m 0 --command='AT+CGACT=1,2'
        # Create network manager profile for gsm
        nmcli con add type gsm ifname '*' con-name wwan0 apn stream.co.uk
        # Bring up gsm connection
        nmcli r wwan on
    fi
    sleep 60
done
