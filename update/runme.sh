#!/bin/bash

func pre_update() {
    echo "START pre-update"
    echo "END pre-update"
}

func update() {
    echo "START update"
    snap install --devmode pelion-edge_1.0_amd64.snap
    echo "END update"
}

func post_update() {
    echo "START post-update"
    cp platform_version ${SNAP_DATA}/etc/
    echo "END post-update"
}

func main() {
    pre_update "$@"
    update "$@"
    post_update "$@"
}

main "$@"
