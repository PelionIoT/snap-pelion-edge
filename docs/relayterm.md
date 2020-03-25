# snap-pelion-edge

This repository contains snapcraft packaging for Pelion Edge. This lets you run Pelion Edge on Ubuntu.

### Relay term install notes
1. Build it.

1. Install the snap:
```
$ sudo snap install pelion-edge_1.5_amd64_con_dev.snap –devmode
```
1. Rrestart maestro after you are sure it registered to Pelion:
```
$ sudo snap restart pelion-edge.maestro
```
1. Make the connections to allow nmcli, mmcli and snap to work in the remote terminal.
```
$ sudo snap connect pelion-edge:snapd-control :snapd-control
$ sudo snap connect pelion-edge:modem-manager modem-manager:service
$ sudo snap connect pelion-edge:network-manager network-manager:service
```
1. Open the terminal in the Pelion portal and verify that nmcli, mmcli and snap commands work.  NOTE: The edge features must be enabled on your Pelion account to see the remote terminal tab.

The restart for maestro is due to a race condition with the credential generation for the terminal feature after the device bootstraps the first time.  I did not find a quick fix other than to restart maestro after the device bootstraps in order to generate the remote terminal creds in ".ssl" path..  
