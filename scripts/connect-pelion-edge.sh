#!/bin/bash

set -e

snap connect pelion-edge:system-observe :system-observe
snap connect pelion-edge:mount-observe :mount-observe
snap connect pelion-edge:network-bind :network-bind
snap connect pelion-edge:process-control :process-control
snap connect pelion-edge:hardware-observe :hardware-observe
snap connect pelion-edge:kubernetes-support :kubernetes-support
snap connect pelion-edge:block-devices :block-devices
snap connect pelion-edge:firewall-control :firewall-control
snap connect pelion-edge:network-control :network-control
snap connect pelion-edge:network-observe :network-observe
snap connect pelion-edge:network-setup-observe :network-setup-observe