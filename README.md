# snap-pelion-edge

This repository contains snapcraft packaging for Pelion Edge. This lets you run Pelion Edge on Ubuntu.

## Prerequisites

### Build prerequisites

- a Linux box with Docker configured (other operating systems may work but aren't supported)
- git

### User account prerequisites

1. [A Pelion Device Management account](https://os.mbed.com/account/signup/).
1. [Access to Device Management](https://console.mbed.com/cloud-registration).
1. An [Ubuntu SSO account](https://login.ubuntu.com/). This is required for an Ubuntu Core installation.
1. An SSH key [uploaded into your Ubuntu SSO account](https://login.ubuntu.com/ssh-keys) so you can SSH into your Ubuntu SSO account. Please see the [Ubuntu instructions](https://help.ubuntu.com/community/SSH/OpenSSH/Keys) for more information about generating an SSH key on your computer.

## Build Pelion Edge

1. Clone the `snap-pelion-edge` repository:

    ```bash
    git clone https://github.com/armpelionedge/snap-pelion-edge
    cd snap-pelion-edge
    ```

1. To support firmware updates - also known as Firmware Over-the-Air (FOTA) - locate the `edge-core` component in the `parts` section of `snap/snapcraft.yaml` and set `FIRMWARE_UPDATE=ON`:

    ```
    parts:
        edge-core:
          ...
          configflags:
            - -DFIRMWARE_UPDATE=ON
    ```

1. Decide if you will be using production or developer mode when building your snap. Documentation on the choices for certificate configuration modes can be found at [Configuring Edge Build](https://github.com/ARMmbed/mbed-edge#configuring-edge-build)

    * [Developer Mode] Generate a device certificate from the Device Management Portal:

      1. Change the definitions of `DEVELOPER_MODE` and `FACTORY_MODE` in `snap/snapcraft.yaml` to `DEVELOPER_MODE=ON` and `FACTORY_MODE=OFF`
      1. Log in to the [Device Management Portal](https://portal.mbedcloud.com/login), and select **Device identity > Certificates**.
      1. If you don't have a certificate, select **New certificate > Create a developer certificate**.
      1. When you have a certificate, and open its panel.
      1. On this panel, click **Download Developer C file** to receive `mbed_cloud_dev_credentials.c`.
      1. Copy `mbed_cloud_dev_credentials.c` to the `snap-pelion-edge` directory:

          ```bash
          cp /path/to/mbed_cloud_dev_credentials.c /path/to/snap-pelion-edge/.
          ```

    * [Production Mode] Do not use the device certificate from the Device Management Portal. Turn off by:

      1. Change the definitions of `DEVELOPER_MODE` and `FACTORY_MODE` in `snap/snapcraft.yaml` to `DEVELOPER_MODE=OFF` and `FACTORY_MODE=ON`
      1. Follow the documentation for [Factory Provisioning](https://www.pelion.com/docs/device-management-provision/1.2/introduction/index.html)
      1. Make sure to specify the `class-id` and `vendor-id` values in `fcu.yml` as specified in the next section.
      1. If enabling firmware updates, make sure to set `update-auth-certificate-file` in `fcu.yml` to the path of the firmware update certificate `default.der` created in the next section.

1. Generate firmware update certificates using the [manifest-tool](https://github.com/armmbed/manifest-tool)

    1. Check that support for firmware updates is enabled in `snap/snapcraft.yaml` with `FIRMWARE_UPDATE=ON`
    1. Install the manifest-tool: `pip install manifest-tool`
    1. Obtain an API key from the [Pelion Edge Access Management Portal](https://portal-os2.mbedcloudstaging.net/access/keys/list)
    1. Generate certificates using the manifest-tool:

      ```bash
      manifest-tool init -a <api-key> --vendor-id 42fa7b48-1a65-43aa-890f-8c704daade54 --class-id 42fa7b48-1a65-43aa-890f-8c704daade54 --force
      ```
      This operation creates the following files:
      1. `update_default_resources.c` required when DEVELOPER_MODE=ON
      1. `.manifest_tool.json` required when creating a manifest file for firmware updates.  See the Update Pelion Edge section for more info.
      1. `.update-certificates/` folder containing `default.der` and `default.key.pem`, required when creating a manifest file for firmware updates and for factory provisioning when FACTORY_MODE=ON.

1. Make sure your `~/.ssh/id_rsa.pub` key is registered with `github.com` and `gitlab.com`, and that they both exist in `known_hosts` (for example, by running `ssh -T git@github.com` and `ssh -T git@gitlab.com`).

1. Build with the snapcraft Docker image:

    ```bash
    docker build --no-cache -f Dockerfile --label snapcore/snapcraft --tag ${USER}/snapcraft:latest .
    docker run --rm -v "$PWD":/build -w /build -v ${HOME}/.ssh:/root/.ssh -v ${HOME}/.gitconfig:/root/.gitconfig ${USER}/snapcraft:latest bash -c "sudo apt-get update && snapcraft --debug"
    ```

   Note: Running the build in Docker may contaminate your project folders with files owned by root and causes a *permission denied* error when you run the build outside of Docker. Run `sudo chown --changes --recursive $USER:$USER _project_folder_` to fix it.

   Note: If you are doing incremental builds, when cleaning a snap with manual override sections which use git commands, you must clean `docker-git` as well, otherwise you'll get template and https helper errors when building. Here is how you rebuild `edge-core`:

    ```bash
    docker run --rm -v "$PWD":/build -w /build -v ${HOME}/.ssh:/root/.ssh -v ${HOME}/.gitconfig:/root/.gitconfig ${USER}/snapcraft:latest bash -c "sudo apt-get update && snapcraft clean edge-core docker-git && snapcraft --debug"
    ```

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
   sudo snap install pelion-edge_<version>_<arch>.snap
   ```

   If you see the following message:

   ```bash
    error: cannot find signatures with metadata for snap
    ```

   add the `--dangerous` option

   ```bash
    sudo snap install --dangerous pelion-edge_<version>_<arch>.snap
    ```

1. Hookup the following connections

    ```bash
    sudo snap connect pelion-edge:snapd-control :snapd-control
    sudo snap connect pelion-edge:modem-manager modem-manager:service
    sudo snap connect pelion-edge:network-manager network-manager:service
    sudo snap connect pelion-edge:network-control :network-control
    sudo snap connect pelion-edge:privileged :docker-support
    sudo snap connect pelion-edge:support :docker-support
    sudo snap connect pelion-edge:firewall-control :firewall-control
    sudo snap connect pelion-edge:docker-cli pelion-edge:docker-daemon
    sudo snap connect pelion-edge:log-observe :log-observe
    sudo snap connect pelion-edge:system-files :system-files
    sudo snap connect pelion-edge:kernel-module-observe :kernel-module-observe
    sudo snap connect pelion-edge:system-trace :system-trace
    sudo snap connect pelion-edge:system-observe :system-observe
    sudo snap connect pelion-edge:account-control :account-control
    sudo snap connect pelion-edge:block-devices :block-devices
    sudo snap connect pelion-edge:bluetooth-control :bluetooth-control
    sudo snap connect pelion-edge:hardware-observe :hardware-observe
    sudo snap connect pelion-edge:kubernetes-support :kubernetes-support
    sudo snap connect pelion-edge:mount-observe :mount-observe
    sudo snap connect pelion-edge:netlink-audit :netlink-audit
    sudo snap connect pelion-edge:netlink-connector :netlink-connector
    sudo snap connect pelion-edge:network-observe :network-observe
    sudo snap connect pelion-edge:process-control :process-control
    sudo snap connect pelion-edge:shutdown :shutdown
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

- Use one of the following commands to stop Pelion Edge:

    ```bash
    snap stop pelion-edge
    ```

    or

    ```bash
    systemctl stop snap.pelion-edge.edge-core
    ```

- To reset your local Device Management credentials, stop Pelion Edge, and run `pelion-edge.edge-core-reset-storage`:

    ```bash
    snap stop pelion-edge
    pelion-edge.edge-core-reset-storage
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

## RelayTerm

For more information on relayTerm, see the `docs` folder

## Update Pelion Edge

This section explains how to:

* [Generate a firmware update package](#generate-a-firmware-update-package) that can be pushed down to a device through a firmware update campaign.
* [Initiate a firmware update campaign](#initiate-a-firmware-update-campaign).

### Generate a firmware update package

A firmware update package is a tar.gz file containing at minimum a bash script, called `runme.sh`, and a version file, called `platform_version`.

The `runme.sh` script implements the logic for performing an update of system components. The script calls `snap install` on any snaps contained within the firmware update package, and performs any other tasks required for the current update campaign.

platform_version should contain a single text string representing the combined versions of the software running on the device that is managed through this firmware update mechanism.  This version string is reported to Pelion Cloud under LwM2M resource ID `/10252/0/10` - `PlatVersion`.

Example runme.sh script:

```bash
#!/bin/bash
set -eux

snap install --devmode pelion-edge_1.0_amd64.snap
```

This example `runme.sh` script assumes a firmware update tar.gz with the following contents:

```bash
$ tar -tzf firmware-update.tar.gz`
./
./platform_version
./runme.sh
./pelion-edge_1.0_amd64.snap
```

#### Important Notes Regarding runme.sh
1. Make sure the script has execute privileges `chmod a+x runme.sh` otherwise the firmware update will fail.
1. If the pelion-edge snap itself is being upgraded, it is recommended to upgrade it in its own update campaign, i.e., it is the only snap file in the firmware update tar.gz.  If it must be bundled with other snaps, or if the runme.sh performs other tasks, make sure that pelion-edge is updated last in the runme.sh because any commands in runme.sh that occur after `snap install pelion-edge` will not be executed due to the manner in which snapd performs snap updates.

    For example, do this:
    ```
    snap ack curl.assert
    snap install curl.snap
    snap install --devmode pelion-edge_amd64.snap
    ```

    not this:
    ```
    snap install --devmode pelion-edge_amd64.snap
    snap ack curl.assert
    snap install curl.snap
    ```
    Any code that occurs after `snap install pelion-edge` will not be executed, so in this case the curl snap and assertion will not be installed.

#### To create a firmware update tar.gz package:

1. Create a folder to hold the contents of the firmware update package.

    You can use this repo's `update/` folder as a skeleton.

1. Build or gather updated snap packages.

    This includes the Pelion Edge snap and any other snap packages you need to update on the remote device.

1. Copy the updated snaps into the `update/` folder.

1. Modify the example `update/runme.sh` script as required. For example, add instructions to run `snap install` on each snap you intend to update.

1. Modify the example `update/platform_version` file with the new version.

    The version must be a single string that encompasses all software packages being managed by this firmware update mechanism, and not necessarily limited to the Pelion Edge snap version.

1. Create the firmware update tar.gz package from the contents of the `update/` folder:

  	```bash
  	tar -czf firmware-update.tar.gz -C update/ .
  	```

### Initiate a firmware update campaign

Device Management pushes your firmware update package down to a defined set of devices, which unpack the firmware update package and apply the updates within it.

You can initiate a firmware update campaign targeting any registered device from Device Management Portal.

<span class="notes">**Note:** You can also initiate a firmware update campaign using the APIs, [as explained in the Pelion Device Management online documentation](https://www.pelion.com/docs/device-management/current/updating-firmware/update-api-tutorial.html).</span>

**To initiate a firmware update campaign:**

1. Upload the firmware update tar.gz package to Pelion Device Management:

    1. Log in to Device Management Portal.
    1. From the left navigation pane, select **Firmware Update** > **Images**.
    1. Click the **+ Upload Image** button.
    1. Follow the instructions on the screen to upload the tar.gz file.

        After you upload the file, Device Management Portal displays a URL from which devices can download the tar.gz file.

1. Create a firmware update manifest:

    1. Gather the update certificate, private key, and manifest_tool.json file created by `manifest-tool init` in the Build Pelion Edge section of this README, which includes `.update-certificates/default.der`, `.update-certificates/default.key.pem` and `.manifest_tool.json`.  Copy these files to the directory where you are preparing the firmware update to be used in the following step.
    1. Use the manifest-tool utility to create a manifest file for your firmware update tar.gz package.  The manifest-tool utility requires the files certificate and manifest_tool.json copied in the previous step.

        ```bash
        manifest-tool create -u <firmware.url> -p <firmware-update.tar.gz> -o manifest
        ```
        * `<firmware.url>` is the URL of the firmware update tar.gz package, as shown in Device Management Portal. Devices use this URL to download the firmware update image.
        * `<firmware-update.tar.gz>` is the firmware update package tar.gz file. The manifest-tool utility calculates a hash from the firmware update tar.gz.
        * make sure `.manifest_tool.json` is in the current directory
        * make sure `.update-certificates/` folder is in the current directory

1. Upload the firmware update manifest to Device Management:

    1. From the left navigation pane, select **Firmware Update** > **Manifests**.
    1. Click the **+ Upload Manifest** button.
    1. Follow the instructions on the screen to upload the manifest file.

1. Create a device filter to select a set of registered devices that should receive the firmware update package:
    1. From the left navigation pane, select **Device directory** > **Devices**.
    1. In the grey bar above the list of devices, click the arrow next to **Filters**.
    1. Choose an attribute and operator, and give a value, such as **Device ID**.
        * To combine multiple attributes in one filter, click **Add another**.
        * To use a raw string instead, click **Advanced view**.
    1. Click **Save**.

        This opens the **Filter name** popup window.
    1. Give your filter a name.
    1. Click **Save filter**.

1. Create the campaign:

    1. From the left navigation pane, select **Firmware Update** > **Update campaigns**.
    1. Click the **+ New Campaign** button.
    1. Populate the **Name** and **Description** (optional) fields.
    1. From the **Manifest** dropdown list, select the manifest file uploaded earlier.
    1. From the **Filter** dropdown list, select the filter that targets the devices you need to update.
    1. Click **Finish** to start the campaign.

### Using port 443 

To use port 443 for the for Pelion-Cloud connection:

1. Run the following: ``` sed -i 's,\(coaps://[^:]*:\)5684,\1443,' mbed_cloud_dev_credentials.c ```
1. Do a clean build following the instruction above in this readme.
