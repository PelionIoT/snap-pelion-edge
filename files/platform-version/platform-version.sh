#!/bin/bash
curl -sS --unix-socket /run/snapd.socket http://localhost/v2/snaps -X GET | jq -r '[.result[]|{id,revision}]|sort_by(.id,.revision)' | md5sum | cut -f 1 -d " "
