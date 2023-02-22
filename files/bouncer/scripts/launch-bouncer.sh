#!/bin/bash
# ----------------------------------------------------------------------------
# Copyright (c) 2021, Arm Limited and affiliates.
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

# add ${SNAP} to PATH edge-core can run the factory reset script: edge-core-factory-reset
exec env PATH="${PATH}:${SNAP}" "${SNAP}/bin/bouncer" "/run/snap.${SNAP_INSTANCE_NAME}/var/run/docker-proxy.sock" "/run/snap.${SNAP_INSTANCE_NAME}/var/run/docker.sock"
