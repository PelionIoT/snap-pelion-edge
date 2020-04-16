#!/bin/bash

export PATH=${SNAP}/wigwag/system/bin:${PATH}
export NODE_PATH=${SNAP}/wigwag/devicejs-core-modules/node_modules

#NOTE: The following use of `false` will cause this subsequent while loop to
# run its loop body. This implements a construct similar to C's `do { ... } while`.
# This makes this shell script a bit hard to reason about, so if the loop body
# grows beyond a single sleep and shell call, replace it with more idiomatic bash.
false
while [ $? -ne 0 ]
do
  sleep 5
  sh $1/wigwag/wwrelay-utils/debug_scripts/create-new-eeprom-with-self-signed-certs.sh\
    $1/wigwag 8081 $2/userdata/edge_gw_identity
done

