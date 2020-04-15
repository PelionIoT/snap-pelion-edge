#!/bin/bash
set -eux


function pre_update() {
    echo "START pre-update"
    echo "END pre-update"
}

function update() {
    echo "START update"
    snap install --devmode pelion-edge_1.0_amd64.snap
    echo "END update"
}

function post_update() {
    echo "START post-update"
    echo "END post-update"
}

function main() {
    pre_update "$@"
    update "$@"
    post_update "$@"
}

main "$@"
