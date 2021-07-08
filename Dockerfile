FROM snapcore/snapcraft@sha256:6d771575c134569e28a590f173f7efae8bf7f4d1746ad8a474c98e02f4a3f627

# Optional environment variables that allow the use of an HTTP/HTTPS proxy while building
# ARG http_proxy="http://<user>:<password>@<proxy-ip>:<proxy-port>"
# ARG https_proxy="https://<user>:<password>@<proxy-ip>:<proxy-port>"
ARG http_proxy=""
ARG https_proxy=""

# Use the proxy from docker build for the container runtime environment as well
ENV http_proxy=$http_proxy
ENV https_proxy=$https_proxy

# Install dependencies
# Gosu is installed so that we can run snapcraft as the current user instead of as root
RUN apt-get update && apt-get install -y \
	curl jq squashfs-tools openssh-client git gosu

# Install Go
# Download the go binary package, unpack it in the proper place,
# and link the go binaries to make them available to snapcraft
RUN curl -L https://dl.google.com/go/go1.15.13.linux-amd64.tar.gz | tar -xz && \
    mv go /usr/local/go1.15 && \
    ln -sf /usr/local/go1.15/bin/go /usr/local/bin/go && \
    ln -sf /usr/local/go1.15/bin/gofmt /usr/local/bin/gofmt

RUN curl -L https://golang.org/dl/go1.17.linux-amd64.tar.gz | tar -xz && \
    mv go /usr/local/go1.17

# Install the script that sets up the user environment
# and runs CMD as the current user instead of as root
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
