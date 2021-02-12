FROM snapcore/snapcraft@sha256:6d771575c134569e28a590f173f7efae8bf7f4d1746ad8a474c98e02f4a3f627

# Faster mirrors
RUN echo "deb mirror://mirrors.ubuntu.com/mirrors.txt trusty main restricted universe multiverse" > /etc/apt/sources.list && \
    echo "deb mirror://mirrors.ubuntu.com/mirrors.txt trusty-updates main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb mirror://mirrors.ubuntu.com/mirrors.txt trusty-security main restricted universe multiverse" >> /etc/apt/sources.list && \
    DEBIAN_FRONTEND=noninteractive apt-get update

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
