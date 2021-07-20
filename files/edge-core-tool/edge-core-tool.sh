#!/bin/bash
# ----------------------------------------------------------------------------
# Copyright (c) 2021, Pelion and affiliates.
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

edge_tool="${SNAP}/wigwag/mbed/edge-tool/edge_tool.py"
if [ ! -x ${edge_tool} ]; then
    echo "ERROR: edge_tool.py is not installed. To install edge_tool.py, rebuild the snap with 'grade: devel'."
    exit 1
fi

if [ ! -f ${HOME}/.mbed_cloud_config.json} ] && [ ! -f ${SNAP_REAL_HOME}/.mbed_cloud_config.json ]; then
    echo "ERROR: config file not found: HOME/.mbed_cloud_config.json"
    echo "To get started, create a file \${HOME}/.mbed_cloud_config.json with the following contents:"
    echo "    { \"api_key\": \"API_KEY\" } "
    echo "Depending on the parameters passed to edge_tool, you may need to specify a valid API_KEY."
    echo "Please see the documentation https://github.com/PelionIoT/mbed-edge/tree/0.16.1/edge-tool."
    exit 2
fi

exec python3 ${edge_tool} ${@}
