FROM snapcore/snapcraft:stable

# Install dependencies
RUN apt update
RUN apt dist-upgrade --yes
RUN apt install --yes curl jq squashfs-tools

# Grab the go snap from the stable channel and unpack it in the proper place
RUN curl -L $(curl -H 'X-Ubuntu-Series: 16' 'https://api.snapcraft.io/api/v1/snaps/details/go?channel=stable' | jq '.download_url' -r) --output go.snap
RUN mkdir -p /snap/go
RUN unsquashfs -d /snap/go/current go.snap

# Link the go binaries to make them available to snapcraft
RUN ln -sf /snap/go/current/bin/go /snap/bin/go
RUN ln -sf /snap/go/current/bin/gofmt /snap/bin/gofmt
