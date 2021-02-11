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

# Add local user that matches the $PWD owner and run command as that user
USER_ID=$(stat -c "%u" ${PWD})
echo "${PWD} is owned by UID ${USER_ID}.  Starting as that UID"
useradd --shell /bin/bash -u ${USER_ID} -o -c "" -m user

# Give the user sudo privileges so that snapcraft can install required packages
usermod -aG sudo user
echo "user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Run the command as user
export HOME=/home/user
exec gosu user "$@"
