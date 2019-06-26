FROM snapcore/snapcraft:stable

RUN apt-get update && apt-get install -y --no-install-recommends \
    ssh

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    build-essential \
    cmake
