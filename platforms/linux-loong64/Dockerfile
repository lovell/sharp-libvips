FROM ubuntu:24.04
LABEL maintainer="Lovell Fuller <npm@lovell.info>"

## Copyright 2017 Lovell Fuller and others.
## SPDX-License-Identifier: Apache-2.0

# Create Ubuntu 24.04 (glibc 2.39) container suitable for cross-compiling Linux LoongArch 64-bit binaries

# Path settings
ENV \
  RUSTUP_HOME="/usr/local/rustup" \
  CARGO_HOME="/usr/local/cargo" \
  PATH="/usr/local/cargo/bin:/root/.local/bin:$PATH"

# Build dependencies
RUN \
  apt-get update && \
  apt-get install -y \
    autoconf \
    automake \
    autopoint \
    bzip2 \
    cmake \
    curl \
    g++-14-loongarch64-linux-gnu \
    gcc-14-loongarch64-linux-gnu \
    gettext \
    git \
    gperf \
    jq \
    libcurl4-openssl-dev \
    libc6-dev-loong64-cross \
    libssl-dev \
    libtool \
    ninja-build \
    patch \
    pipx \
    pkgconf \
    tar \
    xz-utils \
    && \
  curl https://sh.rustup.rs -sSf | sh -s -- -y \
    --no-modify-path \
    --profile minimal \
    --target loongarch64-unknown-linux-gnu \
    --default-toolchain nightly \
    && \
  cargo install cargo-c --locked && \
  pipx install meson

# Compiler settings
ENV \
  CC="loongarch64-linux-gnu-gcc-14" \
  CXX="loongarch64-linux-gnu-g++-14" \
  PKG_CONFIG="loongarch64-linux-gnu-pkg-config --static" \
  PLATFORM="linux-loong64" \
  CHOST="loongarch64-linux-gnu" \
  RUST_TARGET="loongarch64-unknown-linux-gnu" \
  FLAGS="-march=la64v1.0" \
  RUSTFLAGS="-Clinker=loongarch64-linux-gnu-gcc-14 -Zlocation-detail=none -Zfmt-debug=none" \
  MESON="--cross-file=/root/meson.ini"

COPY Toolchain.cmake /root/
COPY meson.ini /root/
COPY loongarch64-linux-gnu-pkg-config /usr/bin/
