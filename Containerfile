ARG SERIES=resolute
FROM ubuntu:${SERIES}

ENV DEBIAN_FRONTEND=noninteractive

# Pin the sources explicitly rather than trusting whatever the base image
# ships: universe is required for several build-deps. amd64 host only — an
# arm64 host would need ports.ubuntu.com here.
RUN . /etc/os-release \
 && printf '%s\n' \
    'Types: deb' \
    'URIs: http://archive.ubuntu.com/ubuntu/' \
    "Suites: ${VERSION_CODENAME} ${VERSION_CODENAME}-updates ${VERSION_CODENAME}-security" \
    'Components: main restricted universe multiverse' \
    'Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg' \
    > /etc/apt/sources.list.d/ubuntu.sources

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    cmake \
    debhelper \
    devscripts \
    gnupg2 \
    lintian \
    ubuntu-dev-tools \
 && rm -rf /var/lib/apt/lists/*
# ubuntu-dev-tools pulls in dput-ng, which provides the `dput` command used for
# PPA uploads. The standalone dput package conflicts with it.

CMD ["bash"]
