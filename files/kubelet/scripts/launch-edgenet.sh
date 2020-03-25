#!/bin/bash

docker network inspect edgenet &>/dev/null || docker network create --subnet=10.0.0.0/24 --gateway=10.0.0.1 edgenet
