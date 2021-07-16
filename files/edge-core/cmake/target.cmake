MESSAGE ("Building standard x86_64 desktop Linux target")
SET (OS_BRAND Linux)
SET (MBED_CLOUD_CLIENT_DEVICE x86_x64)
SET (PAL_TARGET_DEVICE x86_x64)

MESSAGE ("Using SNAPCRAFT_PROJECT_NAME: $ENV{SNAPCRAFT_PROJECT_NAME}")
add_definitions ("-DSNAPCRAFT_PROJECT_NAME=\"$ENV{SNAPCRAFT_PROJECT_NAME}\"")

# the path to the mcc_config folder is needed by the launch-edge-core.sh script, so if this
# path changes make sure to update the script.
SET (PAL_FS_MOUNT_POINT_PRIMARY "\"/var/snap/$ENV{SNAPCRAFT_PROJECT_NAME}/current/userdata/mbed/mcc_config\"")
SET (PAL_FS_MOUNT_POINT_SECONDARY "\"/var/snap/$ENV{SNAPCRAFT_PROJECT_NAME}/current/userdata/mbed/mcc_config\"")
SET (PAL_UPDATE_FIRMWARE_DIR "\"/var/snap/$ENV{SNAPCRAFT_PROJECT_NAME}/current/upgrades\"")
SET (PAL_USER_DEFINED_CONFIGURATION "\"${CMAKE_CURRENT_SOURCE_DIR}/config/sotp_fs_linux.h\"")

if (${FIRMWARE_UPDATE})
  SET (MBED_CLOUD_CLIENT_UPDATE_STORAGE "ARM_UCP_LINUX_GENERIC")
endif()

