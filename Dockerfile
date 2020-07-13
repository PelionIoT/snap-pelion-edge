FROM snapcore/snapcraft@sha256:33f891e3c7ad6981b217460e2e903fabbfd4b9db4dced14f1ad982c4529130cf

# Install dependencies
# Gosu is installed so that we can run snapcraft as the current user instead of as root
RUN apt-get update && apt-get install -y \
	curl jq squashfs-tools openssh-client git gosu

# Install Go
# Download the go binary package, unpack it in the proper place,
# and link the go binaries to make them available to snapcraft
RUN curl -L https://dl.google.com/go/go1.14.4.linux-amd64.tar.gz | tar -xz && \
    mv go /usr/local && \
    ln -sf /usr/local/go/bin/go /usr/local/bin/go && \
    ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt

# Install the script that sets up the user environment
# and runs CMD as the current user instead of as root
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
