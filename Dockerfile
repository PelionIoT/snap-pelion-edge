FROM snapcore/snapcraft:stable

# Install dependencies
RUN apt update
RUN apt dist-upgrade --yes
RUN apt install --yes curl jq squashfs-tools

# Grab the go snap from the stable channel and unpack it in the proper place
RUN curl -L $(curl -H 'X-Ubuntu-Series: 16' 'https://api.snapcraft.io/api/v1/snaps/details/go?channel=latest/stable' | jq '.download_url' -r) --output go.snap
RUN mkdir -p /snap/go
RUN unsquashfs -d /snap/go/current go.snap

# Link the go binaries to make them available to snapcraft
RUN ln -sf /snap/go/current/bin/go /snap/bin/go
RUN ln -sf /snap/go/current/bin/gofmt /snap/bin/gofmt

# Install gosu so that we can run snapcraft as the current user
# instead of as root
RUN apt install gosu

# Install the script that sets up the user environment
# and runs CMD as the current user instead of as root
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
