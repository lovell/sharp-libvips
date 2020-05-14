FROM debian:buster
LABEL maintainer="Lovell Fuller <npm@lovell.info>"

# Create Debian-based container suitable for cross-compiling Linux ARMv7-A binaries

# Build dependencies
RUN \
  apt-get update && \
  apt-get install -y curl && \
  dpkg --add-architecture armhf && \
  apt-get update && \
  apt-get install -y \
    advancecomp \
    autoconf \
    autopoint \
    cmake \
    crossbuild-essential-armhf \
    gettext \
    git \
    gobject-introspection \
    gperf \
    gtk-doc-tools \
    intltool \
    jq \
    libglib2.0-dev \
    libtool \
    nasm \
    ninja-build \
    patchelf \
    python3-pip \
    texinfo \
    && \
  curl https://sh.rustup.rs -sSf | sh -s -- -y && \
  ~/.cargo/bin/rustup target add arm-unknown-linux-gnueabihf && \
  pip3 install meson==0.53.2

# Compiler settings
ENV \
  PATH="/root/.cargo/bin:$PATH" \
  PKG_CONFIG="/usr/bin/arm-linux-gnueabihf-pkg-config" \
  PLATFORM="linux-armv7" \
  CHOST="arm-linux-gnueabihf" \
  FLAGS="-marm -march=armv7-a -mfpu=neon-vfpv4 -mfloat-abi=hard -s -O3 -fPIC -D_GLIBCXX_USE_CXX11_ABI=0" \
  MESON="--cross-file=/root/meson.ini"

COPY Toolchain.cmake /root/
COPY meson.ini /root/
