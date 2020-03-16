#!/bin/bash

set -e

declare -a file_list=(
    'etc'
    'etc/init.d'
    'wigwag'
    'wigwag/devicejs-core-modules'
    'wigwag/devicejs-core-modules/node_modules'
    'wigwag/etc'
    'wigwag/system'
    'wigwag/system/bin'
    'wigwag/system/lib'
    'wigwag/wwrelay-utils/conf'
    'wigwag/wwrelay-utils/debug_scripts'
    'etc/init.d/maestro.sh'
    'wigwag/etc/versions.json'
    'wigwag/system/bin/devicedb'
    'wigwag/system/bin/grease_echo'
    'wigwag/system/lib/libgrease.so'
    'wigwag/system/lib/libgrease.so.1'
    'wigwag/system/lib/libprofiler.a'
    'wigwag/system/lib/libstacktrace.a'
    'wigwag/system/lib/libtcmalloc_and_profiler.a'
    'wigwag/system/lib/libtcmalloc_debug.a'
    'wigwag/system/lib/libtcmalloc_minimal_debug.a'
    'wigwag/system/lib/libtcmalloc_minimal.a'
    'wigwag/system/lib/libtcmalloc.a'
    'wigwag/system/lib/libTW.a'
    'wigwag/system/lib/libuv.a'
    'wigwag/system/bin/maestro-shell'
    'wigwag/system/bin/standalone_test_logsink'
    'wigwag/system/bin/maestro'
    'wigwag/system/bin/fp-edge'
)

for file in "${file_list[@]}"
do
    echo "Searching for: $PWD/$1$file"
    find "$PWD/$1$file" -maxdepth 1 -print0 | grep -qz .
done

echo "Completed search..."
