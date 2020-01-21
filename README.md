# snap-pelion-edge

This repository contains snapcraft packaging for Pelion Edge. This lets you run Pelion Edge on Ubuntu.

## Prerequisites

### Build prerequisites

- a Linux box with Docker configured (other operating systems may work but aren't supported)
- git

### User account prerequisites

1. [A Pelion Cloud account](https://os.mbed.com/account/signup/).
1. [Access to Pelion Cloud](https://console.mbed.com/cloud-registration).
1. An [Ubuntu SSO account](https://login.ubuntu.com/). This is required for an Ubuntu Core installation. 
1. An SSH key [uploaded into your Ubuntu SSO account](https://login.ubuntu.com/ssh-keys) so you can SSH into your Ubuntu SSO account. Please see the [Ubuntu instructions](https://help.ubuntu.com/community/SSH/OpenSSH/Keys) for more information about generating an SSH key on your computer.

## Build Pelion Edge

1. Clone the `snap-pelion-edge` repository:

    ```bash
    git clone https://github.com/armpelionedge/snap-pelion-edge
    cd snap-pelion-edge
    ```

1. Generate a device certificate from the Device Management Portal:
   
   1. Log in to the [Device Management Portal](https://portal.mbedcloud.com/login), and select **Device identity > Certificates**.
   1. If you don't have a certificate, select **New certificate > Create a developer certificate**.
   1. When you have a certificate, and open its panel.
   1. On this panel, click **Download Developer C file** to receive `mbed_cloud_dev_credentials.c`.

1. Copy `mbed_cloud_dev_credentials.c` to the `snap-pelion-edge` directory:

    ```bash
    cp /path/to/mbed_cloud_dev_credentials.c /path/to/snap-pelion-edge/.
    ```

1. Make sure your `~/.ssh/id_rsa.pub` key is registered with `github.com` and `gitlab.com`, and that they both exist in `known_hosts` (for example, by running `ssh -T git@github.com` and `ssh -T git@gitlab.com`).

1. Build with the snapcraft Docker image:

    ```bash
    docker build --no-cache -f Dockerfile --label snapcore/snapcraft --tag ${USER}/snapcraft:latest .
    docker run --rm -v "$PWD":/build -w /build -v ${HOME}/.ssh:/root/.ssh -v ${HOME}/.gitconfig:/root/.gitconfig ${USER}/snapcraft:latest snapcraft --debug
    ```

   Note: Running the build in Docker may contaminate your project folders with files owned by root and causes a *permission denied* error when you run the build outside of Docker. Run `sudo chown --changes --recursive $USER:$USER _project_folder_` to fix it.

## Install and run Pelion Edge

### Install on Ubuntu Core 16

1. Plug a keyboard and monitor into your device.

1. Power on the device.

1. After booting, the system displays the prompt **Press enter to configure**.

1. Press enter.

1. Select **Start** to begin configuring your network and an administrator account. 

1. Follow the instructions on the screen; you will be asked to configure your network and enter your Ubuntu SSO credentials.

1. At the end of the process, you will see your credentials to access your Ubuntu Core machine:

    ```bash
    This device is registered to <Ubuntu SSO email address>.
    Remote access was enabled via authentication with the SSO user <Ubuntu SSO user name>
    Public SSH keys were added to the device for remote access.
    ```

1. Continue following the Ubuntu 16 instructions below.

### Install the pelion-edge snap on Ubuntu 16

1. Copy the `pelion-edge_<version>_<arch>.snap` package to the device.

1. On your target device update the `/etc/hosts` file. Append these lines to the bottom:

   ```
   146.148.90.233 kaas-edge-nodes.arm.com
   146.148.90.233 kaas-edge-admin.arm.com
   146.148.90.233 fog-proxy.arm.com
   ```

1. Use the `snap` utility to install the snap package:

   ```bash
   sudo snap install --devmode pelion-edge_<version>_<arch>.snap
   ```
   
   If you see the following message:
   
   ```bash
    error: cannot find signatures with metadata for snap
    ```
   
   add the `--devmode` option
   
   ```bash
    sudo snap install --devmode pelion-edge_<version>_<arch>.snap
    ```

## Run Pelion Edge

After the snap is installed, Pelion Edge starts automatically:

    ```bash
    systemctl status snap.pelion-edge.edge-core
    ```
    
- Use one of the following commands to start Pelion Edge:

    ```bash
    snap start pelion-edge
    ```
    
    or
    
    ```bash
    systemctl start snap.pelion-edge.edge-core
    ```
    
- Use one of the following command to stop Pelion Edge:

    ```bash
    snap stop pelion-edge
    ```
    
    or
    
    ```bash
    systemctl stop snap.pelion-edge.edge-core
    ```
    
- To reset your local Pelion Cloud credentials, stop Pelion Edge, and run `pelion-edge.edge-core-reset-storage`:

    ```bash
    snap stop pelion-edge.edge-core
    snap start pelion-edge.edge-core-reset-storage
    ```

These are just convenient snap commands that run the binaries. The actual binaries are at `/snap/pelion-edge/current/`. Use the [Pelion Edge docs](https://github.com/armpelionedge/snap-pelion-edge#general-info-for-running-the-binaries) for information about running the binaries directly.

## View Pelion Edge logs

Log files are captured by snap and are available with the following commands:

- To dump the whole log:
   
   ``` bash
   snap logs -n=all pelion-edge.edge-core
   ```
   
- To follow the log (print new lines as they come in):
   
   ``` bash
   snap logs -f pelion-edge.edge-core
   ```
   
   Alternatively, you can use `journalctl`.

- To dump the whole log:
   
   ```bash
   journalctl -u snap.pelion-edge.edge-core -a
   ```
   
- To follow the log (print new lines as they come in):
   
   ```bash
   journalctl -u snap.pelion-edge.edge-core -f
   ```

## Known issues and troubleshooting

### Edge service errors

If you see this error:

```
2018-09-13 18:14:13.771 tid:   6932 [ERR ][esfs]: esfs_create() - pal_fsFopen() for working dir file failed
2018-09-13 18:14:13.772 tid:   6932 [ERR ][fcc ]: storage.c:283:storage_file_create:File already exist in ESFS (esfs_status 5)
2018-09-13 18:14:13.773 tid:   6932 [ERR ][fcc ]: storage.c:131:storage_file_write:<=== Failed to create new file
2018-09-13 18:14:13.774 tid:   6932 [ERR ][fcc ]: key_config_manager.c:206:kcm_item_store:Failed writing file to storage
2018-09-13 18:14:13.775 tid:   6932 [ERR ][fcc ]: fcc_dev_flow.c:96:fcc_developer_flow:<=== Store status: 8, Failed to store mbed.UseBootstrap
2018-09-13 18:14:13.958 tid:   6932 [ERR ][esfs]: esfs_close() failed with bad parameters
2018-09-13 18:14:13.961 tid:   6932 [ERR ][fcc ]: storage.c:366:storage_file_close:<=== Failed closing file (esfs_status 1)
2018-09-13 18:14:14.002 tid:   6932 [ERR ][fcc ]: storage.c:434:storage_file_read_with_ctx:<=== Buffer too small
2018-09-13 18:14:14.003 tid:   6932 [ERR ][fcc ]: key_config_manager.c:309:kcm_item_get_data:Failed reading file from storage (3)
```

Please reset your credentials by running the `pelion-edge.edge-core-reset-storage` app:

```bash
sudo snap stop pelion-edge
sudo pelion-edge.edge-core-reset-storage
```

### Edge startup errors

If you see the following error when starting Edge core, you are probably attempting to start Edge core while running on a LiveUSB or LiveCD Ubuntu system: 

```
/snap/core/current/usr/lib/snapd/snap-confine: error while loading shared libraries:
    libudev.so.1: cannot open shared object file: No such file or directory
```

This is known to not work. The remedy is to install Ubuntu onto the system or use a virtual machine.

## Verify build

We have provided a shell script that will verify that all the files and folders have been properly created and deployed into your build.

Run the following script from the home directory in your build environment:

```
./scripts/install_check.sh prime/
```

The `prime/` parameter is the search folder. You can swap this out for your root directory if you are running this script on the install machine.
