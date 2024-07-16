FROM debian:buster
LABEL maintainer="Lovell Fuller <npm@lovell.info>"

# Create Debian 10 (glibc 2.28) container suitable for cross-compiling Linux ARMv7-A binaries

# Path settings
ENV \
  RUSTUP_HOME="/usr/local/rustup" \
  CARGO_HOME="/usr/local/cargo" \
  PATH="/usr/local/cargo/bin:$PATH"

# Build dependencies
RUN \
  apt-get update && \
  apt-get install -y curl && \
  dpkg --add-architecture armhf && \
  apt-get update && \
  apt-get install -y \
    autoconf \
    autopoint \
    cmake \
    crossbuild-essential-armhf \
    gettext \
    git \
    gperf \
    jq \
    libssl-dev \
    libtool \
    ninja-build \
    pkg-config \
    python3-packaging \
    python3-pip \
    && \
  curl https://sh.rustup.rs -sSf | sh -s -- -y \
    --no-modify-path \
    --profile minimal \
    && \
  rustup target add arm-unknown-linux-gnueabihf && \
  cargo install cargo-c && \
  pip3 install meson tomli

# Compiler settings
ENV \
  PKG_CONFIG="arm-linux-gnueabihf-pkg-config --static" \
  PLATFORM="linux-armv7" \
  CHOST="arm-linux-gnueabihf" \
  RUST_TARGET="arm-unknown-linux-gnueabihf" \
  FLAGS="-marm -march=armv7-a -mfpu=neon-vfpv4 -mfloat-abi=hard" \
  MESON="--cross-file=/root/meson.ini"

COPY Toolchain.cmake /root/
COPY meson.ini /root/
