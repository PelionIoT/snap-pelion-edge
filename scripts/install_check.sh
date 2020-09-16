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

set -e

declare -a file_list=(
    'etc'
    'etc/dnsmasq.d'
    'etc/init.d'
    'etc/network'
    'etc/profile.d'
    'etc/udev'
    'wigwag'
    'wigwag/devicejs-core-modules'
    'wigwag/devicejs-core-modules/core-interfaces'
    'wigwag/wigwag-core-modules/DevStateManager'
    'wigwag/wigwag-core-modules/LEDController'
    'wigwag/devicejs-core-modules/maestroRunner'
    'wigwag/devicejs-core-modules/node_modules'
    'wigwag/wigwag-core-modules/onsite-enterprise-server'
    'wigwag/wigwag-core-modules/relay-term'
    'wigwag/wigwag-core-modules/RelayStatsSender'
    'wigwag/devicejs-core-modules/rsmi'
    'wigwag/wigwag-core-modules/VirtualDeviceDriver'
    'wigwag/devicejs-core-modules/zigbeeHA'
    'wigwag/etc'
    'wigwag/system'
    'wigwag/system/bin'
    'wigwag/system/lib'
    'wigwag/wigwag-core-modules'
    'wigwag/wigwag-core-modules/relay-term'
    'wigwag/wigwag-core-modules/relay-term/config'
    'wigwag/etc/version.json'
    'wigwag/system/lib/libgrease.so'
    'wigwag/system/lib/libgrease.so.1'
    'wigwag/system/lib/libprofiler.a'
    'wigwag/system/lib/libstacktrace.a'
    'wigwag/system/lib/libtcmalloc_and_profiler.a'
    'wigwag/system/lib/libtcmalloc_debug.a'
    'wigwag/system/lib/libtcmalloc_minimal_debug.a'
    'wigwag/system/lib/libtcmalloc_minimal.a'
    'wigwag/system/lib/libtcmalloc.a'
    'wigwag/system/lib/libTW.a'
    'wigwag/system/lib/libuv.a'
    'wigwag/system/bin/maestro-shell'
    'wigwag/system/bin/standalone_test_logsink'
    'wigwag/system/bin/maestro'
    'wigwag/system/bin/edge-proxy'
)

for file in "${file_list[@]}"
do
    echo "Searching for: $PWD/$1$file"
    find "$PWD/$1$file" -maxdepth 1 -print0 | grep -qz .
done

echo "Completed search..."
