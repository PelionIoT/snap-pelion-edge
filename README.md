# snap-pelion-edge
Snapcraft packaging for Pelion Edge

## Prerequisites

### Build Prerequisites
* Ubuntu (or any Linux if using docker)
* git

Install these if you're not using docker:
* snapcraft >= 3.6
* build-essential
* cmake

### User account prerequisites
1. [Create an account on Pelion Cloud](https://os.mbed.com/account/signup/)

1. [Request access to Pelion Cloud](https://console.mbed.com/cloud-registration)

1. Create the required Ubuntu SSO account for an Ubuntu Core installation here: [Ubuntu SSO account](https://login.ubuntu.com/)

1. Import an SSH Key into your Ubuntu SSO account [on this page](https://login.ubuntu.com/ssh-keys). Instructions to generate an SSH Key on your computer can be found [here](https://help.ubuntu.com/community/SSH/OpenSSH/Keys).


## Build Pelion-Edge


1. Clone the 'snap-pelion-edge' repository:
    ```bash
    git clone https://github.com/armpelionedge/snap-pelion-edge
    cd snap-pelion-edge
    ```

1. Generate a device certificate from the Device Management Portal:
    1. Log in to the ['mbed Portal'](https://portal.mbedcloud.com/login), and select Device identity > Certificates.
    1. If you don't have a certificate select:
        1. New certificate > Create a developer certificate.
    1. When you have a certificate generate you can select it and open its panel.
    1. On this panel click 'Download Developer C file' to receive `mbed_cloud_dev_credentials.c`

1. After downloading `mbed_cloud_dev_credentials.c` copy it to the 'snap-pelion-edge' directory:
    ```bash
    cp /path/to/mbed_cloud_dev_credentials.c /path/to/snap-pelion-edge/.
    ```

1. If you have docker you can now build with the snapcraft docker image, or skip this step and follow the rest of the build steps below.
    ```bash
    docker build --no-cache -f Dockerfile --label snapcore/snapcraft --tag ${USER}/snapcraft:latest .
    docker run --rm -v "$PWD":/build -v ${HOME}/.ssh:/root/.ssh -v ${HOME}/.gitconfig:/root/.gitconfig -v ${HOME}/.netrc:/root/.netrc -w /build ${USER}/snapcraft:latest snapcraft --debug
    ```

    Tip: Use the following command to drop you into a shell within the docker container. Once in the docker environment, don't forget to run the entrypoint.sh script to set up your ssh keys.
    ```bash
    docker run --rm -it -v ${HOME}/.ssh:/root/.ssh -v ${HOME}/.gitconfig:/root/.gitconfig -v ${HOME}/.netrc:/root/.netrc -v "${PWD}":/build ${USER}/snapcraft:latest /bin/bash
    ```

1. If you are not using docker, install the snap development tools and other developer tools you might need (snapcraft, build-essential, git, nodejs, bzr, etc.) on your host system.
    ```bash
    sudo apt-get update && sudo apt-get upgrade
    sudo apt-get install snapcraft build-essential git cmake
    ```

    Note: the minimum required version of snapcraft is 3.6 which can be viewed with `snapcraft --version`.  If your version of snapcraft is older than 3.6, then install snapcraft via `snap` instead of `apt-get` or `apt`.
    ```bash
    sudo apt-get remove snapcraft
    sudo snap install --classic snapcraft
    ```

    Note: When you execute snapcraft to build the package, snapcraft will attempt to install additional packages listed under `build-packages` of each part in snapcraft.yaml.  You may be prompted for a sudo password if these packages are not already installed on your dev system.

1. Compile your snap with 'snapcraft' (you may have to type your GitHub credentials during compile)
    ```bash
    snapcraft
    ```

    Note: If you receive an error regarding 'multipass', try building with the following options:
    ```bash
    SNAPCRAFT_BUILD_ENVIRONMENT=host snapcraft --debug
    ```
    This results in a new file `pelion-edge_<version>_<arch>.snap` in the local directory.

## Install and Run Pelion-Edge

### Install on Ubuntu Core 16
1. Plug a keyboard and monitor into your device.

1. Power on the device.

1. After booting, the system will display the prompt “Press enter to configure”.

1. Press enter then select “Start” to begin configuring your network and an administrator account. Follow the instructions on the screen, you will be asked to configure your network and enter your Ubuntu SSO credentials.

1. At the end of the process, you will see your credentials to access your Ubuntu Core machine:
    ```bash
    This device is registered to <Ubuntu SSO email address>.
    Remote access was enabled via authentication with the SSO user <Ubuntu SSO user name>
    Public SSH keys were added to the device for remote access.
    ```

1. Continue following the Ubuntu 16 instructions below.

### Install the snap on Ubuntu 16
1. Copy the `pelion-edge_<version>_<arch>.snap` package to the device.

1. Use the `snap` utility to install the snap package.
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

## Run Pelion Edge
* Once the snap is installed, pelion-edge starts automatically.
    ```bash
    systemctl status snap.pelion-edge.edge-core
    ```
* Use the following command to start pelion-edge.
    ```bash
    snap start pelion-edge
    ```
    or
    ```bash
    systemctl start snap.pelion-edge.edge-core
    ```
* Use the following command to stop pelion-edge.
    ```bash
    snap stop pelion-edge
    ```
    or
    ```bash
    systemctl stop snap.pelion-edge.edge-core
    ```
* If you need to reset your local Pelion Cloud credentials, stop pelion-edge and run pelion-edge.edge-core-reset-storage
    ```bash
    snap stop pelion-edge
    pelion-edge.edge-core-reset-storage
    ```

These are just convenient snap commands that will run the binaries. The actual binaries are located here: `/snap/pelion-edge/current/`. Use the [Pelion Edge docs](https://github.com/armpelionedge/snap-pelion-edge#general-info-for-running-the-binaries) for information about running the binaries directly.

## View Pelion Edge Logs
Log files are captured by snap and are available with the following commands:

To dump the whole log:
``` bash
snap logs -n=all pelion-edge.edge-core
```

To follow the log (print new lines as they come in):
``` bash
snap logs -f pelion-edge.edge-core
```

Alternatively, you can use journalctl.

To dump the whole log:
```bash
journalctl -u snap.pelion-edge.edge-core -a
```

To follow the log (print new lines as they come in):
```bash
journalctl -u snap.pelion-edge.edge-core -f
```

## Known Issues and Troubleshooting

### Edge service errors
If you see an error like below for the edge-service:
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

Please reset your credentials by running the pelion-edge.edge-core-reset-storage app:
```bash
sudo snap stop pelion-edge
sudo pelion-edge.edge-core-reset-storage
```

### Edge startup errors
If you see the following error when starting edge-core, you are probably attempting to start edge-core while running on a LiveUSB or LiveCD Ubuntu system.  This is known to not work.  The remedy is to install Ubuntu onto the system or use a virtual machine.
```
/snap/core/current/usr/lib/snapd/snap-confine: error while loading shared libraries:
    libudev.so.1: cannot open shared object file: No such file or directory
```

## Verify build

We have provided a shell script that will verify that all the files/folders have been properly created and deployed into your build.

Run the following script from the home directory in your build environment:
```
./scripts/install_check.sh prime/
```

The `prime/` parameter is the search folder. You can swap this out for your root directory if you are running this script on the install machine
