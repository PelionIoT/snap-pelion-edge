#!/bin/bash

false
while [ $? -ne 0 ]
do
  sleep 5
  sh $1/wwrelay-utils/debug_scripts/create-new-eeprom-with-self-signed-certs.sh\
    $1 8081 $2/edge_gw_identity $2/pelion-edge/mcc_config
done

