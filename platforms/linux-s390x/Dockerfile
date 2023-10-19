FROM debian:buster
LABEL maintainer="Lovell Fuller <npm@lovell.info>"

# Create Debian 10 (glibc 2.28) container suitable for cross-compiling Linux s390x binaries

# Path settings
ENV \
  RUSTUP_HOME="/usr/local/rustup" \
  CARGO_HOME="/usr/local/cargo" \
  PATH="/usr/local/cargo/bin:$PATH"

# Build dependencies
RUN \
  apt-get update && \
  apt-get install -y curl && \
  dpkg --add-architecture s390x && \
  apt-get update && \
  apt-get install -y \
    advancecomp \
    autoconf \
    autopoint \
    brotli \
    cmake \
    crossbuild-essential-s390x \
    gettext \
    git \
    gperf \
    jq \
    libtool \
    ninja-build \
    pkg-config \
    python3-pip \
    && \
  curl https://sh.rustup.rs -sSf | sh -s -- -y \
    --no-modify-path \
    --profile minimal \
    && \
  rustup target add s390x-unknown-linux-gnu && \
  pip3 install meson

# Compiler settings
ENV \
  PKG_CONFIG="s390x-linux-gnu-pkg-config --static" \
  PLATFORM="linux-s390x" \
  CHOST="s390x-linux-gnu" \
  RUST_TARGET="s390x-unknown-linux-gnu" \
  FLAGS="" \
  # https://github.com/google/highway/issues/1153
  WITHOUT_HIGHWAY="true" \
  MESON="--cross-file=/root/meson.ini"

COPY Toolchain.cmake /root/
COPY meson.ini /root/
