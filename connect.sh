#!/bin/bash

sudo snap connect pelion-edge:snapd-control       :snapd-control
sudo snap connect pelion-edge:modem-manager       modem-manager:service
sudo snap connect pelion-edge:network-manager     network-manager:service
sudo snap connect pelion-edge:network-control     :network-control
sudo snap connect pelion-edge:privileged          :docker-support
sudo snap connect pelion-edge:support             :docker-support
sudo snap connect pelion-edge:firewall-control    :firewall-control
sudo snap connect pelion-edge:docker-cli          pelion-edge:docker-daemon
sudo snap connect pelion-edge:log-observe         :log-observe
sudo snap connect pelion-edge:system-files        :system-files
sudo snap connect pelion-edge:kernel-module-observe :kernel-module-observe
sudo snap connect pelion-edge:system-trace        :system-trace
sudo snap connect pelion-edge:system-observe      :system-observe
sudo snap connect pelion-edge:account-control     :account-control
sudo snap connect pelion-edge:block-devices       :block-devices
sudo snap connect pelion-edge:bluetooth-control   :bluetooth-control
sudo snap connect pelion-edge:hardware-observe    :hardware-observe
sudo snap connect pelion-edge:kubernetes-support  :kubernetes-support
sudo snap connect pelion-edge:mount-observe       :mount-observe
sudo snap connect pelion-edge:netlink-audit       :netlink-audit
sudo snap connect pelion-edge:netlink-connector   :netlink-connector
sudo snap connect pelion-edge:network-observe     :network-observe
sudo snap connect pelion-edge:process-control     :process-control
