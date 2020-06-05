#!/bin/bash
# ----------------------------------------------------------------------------
# Copyright (c) 2020, Arm Limited and affiliates.
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

