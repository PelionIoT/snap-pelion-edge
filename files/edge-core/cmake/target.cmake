MESSAGE ("Building standard x86_64 desktop Linux target")
SET (OS_BRAND Linux)
SET (MBED_CLOUD_CLIENT_DEVICE x86_x64)
SET (PAL_TARGET_DEVICE x86_x64)

SET (PAL_FS_MOUNT_POINT_PRIMARY "\"/var/snap/pelion-edge/current/userdata/pelion-edge/mcc_config\"")
SET (PAL_FS_MOUNT_POINT_SECONDARY "\"/var/snap/pelion-edge/current/userdata/pelion-edge/mcc_config\"")
SET (PAL_USER_DEFINED_CONFIGURATION "\"${CMAKE_CURRENT_SOURCE_DIR}/config/sotp_fs_linux.h\"")

if (${FIRMWARE_UPDATE})
  SET (MBED_CLOUD_CLIENT_UPDATE_STORAGE "ARM_UCP_LINUX_GENERIC")
endif()

