FROM clefos:7
LABEL maintainer="Neale Ferguson <neale@sinenomine.net>"

# Create ClefOS 7 (glibc 2.17) container suitable for building Linux s390x binaries

# Path settings
ENV \
  RUSTUP_HOME="/usr/local/rustup" \
  CARGO_HOME="/usr/local/cargo" \
  PATH="/usr/local/cargo/bin:/opt/rh/devtoolset-11/root/usr/bin:/opt/rh/rh-python38/root/usr/bin:/opt/rh/rh-python38/root/usr/local/bin:$PATH"

# Build dependencies
RUN \
  yum update -y -q && \
  yum install -y -q --enablerepo=extras centos-release-scl && \
  yum --enablerepo=clefos-rh clean metadata && \
  yum install --enablerepo=clefos-rh -y --setopt=tsflags=nodocs \
    advancecomp \
    brotli \
    bzip2 \
    cmake3 \
    devtoolset-11-gcc \
    devtoolset-11-gcc-c++ \
    git \
    glib2-devel \
    gobject-introspection-devel \
    gperf \
    gtk-doc \
    jq \
    nasm \
    ninja-build \
    patch \
    pkgconfig \
    prelink \
    rh-python38-python \
    rh-python38-python-pip \
    rust \
    && \
  curl https://sh.rustup.rs -sSf | sh -s -- -y \
    --no-modify-path \
    --profile minimal \
    && \
  ln -s /usr/bin/cmake3 /usr/bin/cmake && \
  pip3 install meson

# Compiler settings
ENV \
  PLATFORM="linux-s390x" \
  FLAGS="" \
  MESON="--cross-file=/root/meson.ini"

COPY Toolchain.cmake /root/
COPY meson.ini /root/
