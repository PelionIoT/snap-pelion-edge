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

SNAP_NAME=${SNAP_NAME:-pelion-edge}

sudo snap connect ${SNAP_NAME}:snapd-control       :snapd-control
sudo snap connect ${SNAP_NAME}:modem-manager       modem-manager:service
sudo snap connect ${SNAP_NAME}:network-manager     network-manager:service
sudo snap connect ${SNAP_NAME}:network-control     :network-control
sudo snap connect ${SNAP_NAME}:privileged          :docker-support
sudo snap connect ${SNAP_NAME}:support             :docker-support
sudo snap connect ${SNAP_NAME}:firewall-control    :firewall-control
sudo snap connect ${SNAP_NAME}:docker-cli          ${SNAP_NAME}:docker-daemon
sudo snap connect ${SNAP_NAME}:log-observe         :log-observe
sudo snap connect ${SNAP_NAME}:system-files-logs   :system-files
sudo snap connect ${SNAP_NAME}:kernel-module-observe :kernel-module-observe
sudo snap connect ${SNAP_NAME}:system-trace        :system-trace
sudo snap connect ${SNAP_NAME}:system-observe      :system-observe
sudo snap connect ${SNAP_NAME}:account-control     :account-control
sudo snap connect ${SNAP_NAME}:bluetooth-control   :bluetooth-control
sudo snap connect ${SNAP_NAME}:hardware-observe    :hardware-observe
sudo snap connect ${SNAP_NAME}:kubernetes-support  :kubernetes-support
sudo snap connect ${SNAP_NAME}:mount-observe       :mount-observe
sudo snap connect ${SNAP_NAME}:netlink-audit       :netlink-audit
sudo snap connect ${SNAP_NAME}:netlink-connector   :netlink-connector
sudo snap connect ${SNAP_NAME}:network-observe     :network-observe
sudo snap connect ${SNAP_NAME}:process-control     :process-control
sudo snap connect ${SNAP_NAME}:shutdown            :shutdown
sudo snap connect ${SNAP_NAME}:dbus-wpa            wpa-supplicant:service
sudo snap connect ${SNAP_NAME}:home                :home
sudo snap connect ${SNAP_NAME}:edge-tool-files     :personal-files
