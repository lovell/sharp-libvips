FROM debian:bookworm
LABEL maintainer="Lovell Fuller <npm@lovell.info>"

## Copyright 2017 Lovell Fuller and others.
## SPDX-License-Identifier: Apache-2.0

# Create Debian 12 (glibc 2.36) container suitable for cross-compiling Linux ARMv6 binaries

# Path settings
ENV \
  RUSTUP_HOME="/usr/local/rustup" \
  CARGO_HOME="/usr/local/cargo" \
  PATH="/usr/local/cargo/bin:/root/.local/bin:$PATH"

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
    libcurl4-openssl-dev \
    libssl-dev \
    libtool \
    ninja-build \
    pipx \
    pkgconf \
    pkgconf:armhf \
    && \
  curl https://sh.rustup.rs -sSf | sh -s -- -y \
    --no-modify-path \
    --profile minimal \
    --target arm-unknown-linux-gnueabihf \
    --default-toolchain nightly \
    && \
  cargo install cargo-c --locked && \
  pipx install meson

# Compiler settings
ENV \
  PKG_CONFIG="arm-linux-gnueabihf-pkg-config --static" \
  PLATFORM="linux-armv6" \
  CHOST="arm-linux-gnueabihf" \
  RUST_TARGET="arm-unknown-linux-gnueabihf" \
  FLAGS="-marm -mcpu=arm1176jzf-s -mfpu=vfp -mfloat-abi=hard" \
  RUSTFLAGS="-Zlocation-detail=none -Zfmt-debug=none" \
  WITHOUT_NEON="true" \
  # Highway requires NEON (Armv7+)
  WITHOUT_HIGHWAY="true" \
  MESON="--cross-file=/root/meson.ini"

COPY Toolchain.cmake /root/
COPY meson.ini /root/
