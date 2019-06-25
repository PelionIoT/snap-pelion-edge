## How To Install Ubuntu Core 16 on to a Raspberry Pi 3b
1. Download [Ubuntu Core 16 image for Raspberry Pi 3 (edge)](http://cdimage.ubuntu.com/ubuntu-core/16/edge/current/ubuntu-core-16-armhf+raspi3.img.xz) - this image provides reliable Wi-Fi at first boot and contains the latest releases of all software.

1. Install the image on the SD Card
    1. ### On Ubuntu
        1. Insert your SD card or USB flash drive

        1. Identify its address by opening the "Disks" application and look for the "Device" line. If the line is in the /dev/mmcblk0p1 format, then your drive address is: /dev/mmcblk0. If it is in the /dev/sdb1 format, then the address is /dev/sdb

        1. Unmount it by right-clicking its icon in the launcher bar, the eject icon in a file manager or the square icon in the "Disks" application

        1. Open a terminal (Ctrl+Alt+T) to copy the image to your removable drive

        1. If the Ubuntu Core image file you have downloaded ends with an .xz file extension, run:
            ```bash
            xzcat ~/Downloads/<image file .xz> | sudo dd of=<drive address> bs=32M
            Else, run:

            sudo dd if=~/Downloads/<image file> of=<drive address> bs=32M
            Then, run the sync command to finalize the process
            ```

        1. You can now eject your removable drive. You are ready to install Ubuntu Core on your device  ›

    1. ### On Windows

        1. If the Ubuntu Core image file you have downloaded ends with a .xz file extension, you will need to extract it first. To do so, you might have to install an archive extractor software, like 7-zip

        1. Insert your SD card or USB flash drive

        1. Download and install Win32DiskImager, then launch it

        1. Find out where your removable drive is mounted by opening a File Explorer window to check which mount point the drive is listed under. Here is an example of an SD card listed under E:

        1. In order to flash your card with the Ubuntu image, Win32DiskImager will need 2 elements:

            1. an Image File: navigate to your Downloads folder and select the image you have just extracted

            1. a Device: the location of your SD card. Select the drive on which your SD card is mounted

        1. When ready click on Write and wait for the process to complete.

        1. You can now eject your removable drive. You are ready to install Ubuntu Core on your device ›

    1. ### On Mac OS

        1. Insert your SD card or USB flash drive

        1. Open a terminal window (Go to Application -> Utilities, you will find the Terminal app there), then run the following command:
            ```bash
            diskutil list
            ```

        1. In the results, identify your removable drive device address, it will probably look like an entry like the ones below:
            ```bash
            /dev/disk0
              #:                       TYPE NAME                    SIZE       IDENTIFIER
              0:      GUID_partition_scheme                        *500.3 GB   disk0
            /dev/disk2
              #:                       TYPE NAME                    SIZE       IDENTIFIER
              0:                  Apple_HFS Macintosh HD           *428.8 GB   disk1
                                            Logical Volume on disk0s2
                                            E2E7C215-99E4-486D-B3CC-DAB8DF9E9C67
                                            Unlocked Encrypted
            /dev/disk3
              #:                       TYPE NAME                    SIZE       IDENTIFIER
              0:     FDisk_partition_scheme                        *7.9 GB     disk3
              1:                 DOS_FAT_32 NO NAME                 7.9 GB     disk3s1
            ```
        Note that your removable drive must be DOS_FAT_32 formatted. In this example, /dev/disk3 is the drive address of an 8GB SD card.

        1. Unmount your SD card with the following command:
            ```bash
            diskutil unmountDisk <drive address>
            ```

        1. When successful, you should see a message similar to this one:
            ```bash
            Unmount of all volumes on <drive address> was successful
            ```


        1. You can now copy the image to the SD card, using the following command:
            ```bash
            sudo sh -c 'xzcat ~/Downloads/<image file> | sudo dd of=<drive address> bs=32m'
            ```

        1. When finalized you will see the following message:
            ```bash
            3719+1 records in
            3719+1 records out
            3899999744 bytes transferred in 642.512167 secs (6069924 bytes/sec)
            ```

        1. You can now eject your removable drive. You are ready to install Ubuntu Core on your device ›

        1. Insert the Ubuntu Core SD card into your Raspberry Pi 3.

## First Boot
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

## Setup for Local Builds on the Raspberry Pi 3b

1. SSH into the device at the address and username given at the end of the 'First Boot' instructions above. Example:
    ```bash
    ssh ubuntu_user@192.168.0.10
    ```

1. Install the latest version of the "classic" snap from the [edge channel](http://snapcraft.io/docs/reference/channels), with the  --devmode flag to give it unconfined access to the device.
    ```bash
    snap install classic --edge --devmode
    ```

1. Unpack the classic environment and access it using:
    ```bash
    sudo classic
    ```
1. You are now presented with the bash shell of a classic Ubuntu 16.04 LTS environment, ready to install your required snap development tools (snapcraft, build-essential) and other developer tools you might need (git, nodejs, bzr, etc.).
    ```bash
    sudo apt-get update && sudo apt-get upgrade
    sudo apt-get install snapcraft build-essential git
    ```
    Note: the minimum required version of snapcraft is 3.6 which can be viewed with `snapcraft --version`.  If your version of snapcraft is older than 3.6, then install snapcraft via `snap` instead of `apt-get` or `apt`.
    ```bash
    sudo apt remove snapcraft
    sudo snap install --classic snapcraft
    ```
1. Install the Perl developers kit
    ```bash
    sudo apt install libperl-dev
    ```
1. Install the GTK developers kit
    ```bash
    sudo apt install libgtk2.0-dev
    ```
1. Clone the 'snap-pelion-edge' repository:
    ```bash
    git clone https://github.com/armpelionedge/snap-pelion-edge
    ```
1. Generate a device certificate from the Device Management Portal:

    1. Log in to the ['mbed Portal'](https://portal.mbedcloud.com/login), and select Device identity > Certificates.

    1. If you don't have a certificate select:
        1. New certificate > Create a developer certificate.
    1. When you have a certificate generate you can select it and open its panel.
    1. On this panel click 'Download Developer C file' to receive 'mbed_cloud_dev_credentials.c'
1. After downloading 'mbed_cloud_dev_credentials.c' copy it to the 'snap-pelion-edge' directory:
    ```bash
    cp /path/to/mbed_cloud_dev_credentials.c snap-pelion-edge/.
    ```

1. Compile your snap with 'snapcraft' (you may have to type your GitHub credentials during compile)
    ```bash
    snapcraft
    ```
    If you receive an error regarding 'multipass', try building with the following options:
    ```bash
    SNAPCRAFT_BUILD_ENVIRONMENT=host snapcraft --debug
    ```
    1. This will result in a new file `pelion-edge_<version>_<arch>.snap`
