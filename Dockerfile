ARG RISK=stable
ARG UBUNTU=20.04
ARG http_proxy=""
ARG https_proxy=""
# Based on Docker image at;
# https://raw.githubusercontent.com/snapcore/snapcraft/master/docker/Dockerfile
# Update to focal + merged in what we had originally here.

# Optional environment variables that allow the use of an HTTP/HTTPS proxy while building
# ARG http_proxy="http://<user>:<password>@<proxy-ip>:<proxy-port>"
# ARG https_proxy="https://<user>:<password>@<proxy-ip>:<proxy-port>"

# Use the proxy from docker build for the container runtime environment as well
FROM ubuntu:$UBUNTU as builder
ARG RISK
ARG UBUNTU
RUN echo "Building snapcraft:$RISK in ubuntu:$UBUNTU"

ENV http_proxy=$http_proxy
ENV https_proxy=$https_proxy

# Grab dependencies
RUN apt-get update
RUN apt-get dist-upgrade --yes
RUN apt-get install --yes \
      curl \
      jq \
      squashfs-tools \
      git \
      gosu \
      openssh-client

# Grab the core snap (for backwards compatibility) from the stable channel and
# unpack it in the proper place.
RUN curl -L $(curl -H 'X-Ubuntu-Series: 16' 'https://api.snapcraft.io/api/v1/snaps/details/core' | jq '.download_url' -r) --output core.snap
RUN mkdir -p /snap/core
RUN unsquashfs -d /snap/core/current core.snap

# Grab the core18 snap (which snapcraft uses as a base) from the stable channel
# and unpack it in the proper place.
RUN curl -L $(curl -H 'X-Ubuntu-Series: 16' 'https://api.snapcraft.io/api/v1/snaps/details/core18' | jq '.download_url' -r) --output core18.snap
RUN mkdir -p /snap/core18
RUN unsquashfs -d /snap/core18/current core18.snap

# Grab the core20 snap (which snapcraft uses as a base) from the stable channel
# and unpack it in the proper place.
RUN curl -L $(curl -H 'X-Ubuntu-Series: 16' 'https://api.snapcraft.io/api/v1/snaps/details/core20' | jq '.download_url' -r) --output core20.snap
RUN mkdir -p /snap/core20
RUN unsquashfs -d /snap/core20/current core20.snap

# Grab the core22 snap (which snapcraft uses as a base) from the stable channel
# and unpack it in the proper place.
RUN curl -L $(curl -H 'X-Ubuntu-Series: 16' 'https://api.snapcraft.io/api/v1/snaps/details/core22' | jq '.download_url' -r) --output core22.snap
RUN mkdir -p /snap/core22
RUN unsquashfs -d /snap/core22/current core22.snap

# Grab the snapcraft snap from the $RISK channel and unpack it in the proper
# place.
RUN curl -L $(curl -H 'X-Ubuntu-Series: 16' 'https://api.snapcraft.io/api/v1/snaps/details/snapcraft?channel='$RISK | jq '.download_url' -r) --output snapcraft.snap
RUN mkdir -p /snap/snapcraft
RUN unsquashfs -d /snap/snapcraft/current snapcraft.snap

# Fix Python3 installation: Make sure we use the interpreter from
# the snapcraft snap:
RUN unlink /snap/snapcraft/current/usr/bin/python3
RUN ln -s /snap/snapcraft/current/usr/bin/python3.* /snap/snapcraft/current/usr/bin/python3
RUN echo /snap/snapcraft/current/lib/python3.*/site-packages >> /snap/snapcraft/current/usr/lib/python3/dist-packages/site-packages.pth

# Create a snapcraft runner (TODO: move version detection to the core of
# snapcraft).
RUN mkdir -p /snap/bin
RUN echo "#!/bin/sh" > /snap/bin/snapcraft
RUN snap_version="$(awk '/^version:/{print $2}' /snap/snapcraft/current/meta/snap.yaml | tr -d \')" && echo "export SNAP_VERSION=\"$snap_version\"" >> /snap/bin/snapcraft
RUN echo 'exec "$SNAP/usr/bin/python3" "$SNAP/bin/snapcraft" "$@"' >> /snap/bin/snapcraft
RUN chmod +x /snap/bin/snapcraft

# Multi-stage build, only need the snaps from the builder. Copy them one at a
# time so they can be cached.
FROM ubuntu:$UBUNTU
COPY --from=builder /snap/core /snap/core
COPY --from=builder /snap/core18 /snap/core18
COPY --from=builder /snap/core20 /snap/core20
COPY --from=builder /snap/core22 /snap/core22
COPY --from=builder /snap/snapcraft /snap/snapcraft
COPY --from=builder /snap/bin/snapcraft /snap/bin/snapcraft

# Generate locale and install dependencies.
RUN apt-get update && apt-get dist-upgrade --yes && DEBIAN_FRONTEND="noninteractive" apt-get install --yes snapd sudo locales && locale-gen en_US.UTF-8
RUN apt-get install --yes \
      curl \
      jq \
      squashfs-tools \
      git \
      gosu \
      openssh-client \
      software-properties-common \
      libbtrfs-dev \
      rsync
#RUN sudo add-apt-repository ppa:deadsnakes/ppa
#RUN sudo apt-get update && \
#    && DEBIAN_FRONTEND="noninteractive" apt-get install --yes python3.9 virtualenv

# Set the proper environment.
ENV LANG="en_US.UTF-8"
ENV LANGUAGE="en_US:en"
ENV LC_ALL="en_US.UTF-8"
ENV PATH="/snap/bin:/snap/snapcraft/current/usr/bin:$PATH"
ENV SNAP="/snap/snapcraft/current"
ENV SNAP_NAME="snapcraft"
ENV SNAP_ARCH="amd64"

# Install Go
# Download the go binary package, unpack it in the proper place,
# and link the go binaries to make them available to snapcraft
RUN curl -L https://dl.google.com/go/go1.15.15.linux-amd64.tar.gz | tar -xz && \
    mv go /usr/local/go1.15 && \
    ln -sf /usr/local/go1.15/bin/go /usr/local/bin/go && \
    ln -sf /usr/local/go1.15/bin/gofmt /usr/local/bin/gofmt

RUN curl -L https://golang.org/dl/go1.18.10.linux-amd64.tar.gz | tar -xz && \
    mv go /usr/local/go1.18

# Install the script that sets up the user environment
# and runs CMD as the current user instead of as root
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
RUN snapcraft --version
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
