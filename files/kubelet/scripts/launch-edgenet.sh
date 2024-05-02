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
EDGENET_SUBNET=$(snapctl get kubelet.edgenet-subnet)
EDGENET_GATEWAY=$(snapctl get kubelet.edgenet-gateway)

docker network inspect edgenet &>/dev/null
if [ $? -eq 0 ]; then
    # edgenet already exists
    CURRENT_SUBNET=$(docker network inspect --format='{{range .IPAM.Config}}{{.Subnet}}{{end}}' edgenet)
    CURRENT_GATEWAY=$(docker network inspect --format='{{range .IPAM.Config}}{{.Gateway}}{{end}}' edgenet)
    if [[ ${CURRENT_SUBNET} != ${EDGENET_SUBNET} || ${CURRENT_GATEWAY} != ${EDGENET_GATEWAY} ]]; then
        docker network rm edgenet
        docker network create --subnet=${EDGENET_SUBNET} --gateway=${EDGENET_GATEWAY} edgenet
    fi
else
    # edgenet does not already exist
    docker network create --subnet=${EDGENET_SUBNET} --gateway=${EDGENET_GATEWAY} edgenet
fi
