FROM debian:buster
LABEL maintainer="Lovell Fuller <npm@lovell.info>"

# Create Debian 10 (glibc 2.28) container suitable for cross-compiling Linux ARMv6 binaries

# Path settings
ENV \
  RUSTUP_HOME="/usr/local/rustup" \
  CARGO_HOME="/usr/local/cargo" \
  PATH="/usr/local/cargo/bin:/root/tools/x64-gcc-6.5.0/arm-rpi-linux-gnueabihf/bin:$PATH"

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
    gettext \
    git \
    gperf \
    jq \
    libtool \
    ninja-build \
    pkg-config \
    python3-pip \
    && \
  mkdir /root/tools && \
  curl -Ls https://github.com/rvagg/rpi-newer-crosstools/archive/master.tar.gz | tar xzC /root/tools --strip-components=1 && \
  curl https://sh.rustup.rs -sSf | sh -s -- -y \
    --no-modify-path \
    --profile minimal \
    && \
  rustup target add arm-unknown-linux-gnueabihf && \
  pip3 install meson

# Compiler settings
ENV \
  PKG_CONFIG="arm-linux-gnueabihf-pkg-config --static" \
  PLATFORM="linux-armv6" \
  CHOST="arm-rpi-linux-gnueabihf" \
  RUST_TARGET="arm-unknown-linux-gnueabihf" \
  FLAGS="-marm -mcpu=arm1176jzf-s -mfpu=vfp -mfloat-abi=hard" \
  WITHOUT_NEON="true" \
  # Highway requires NEON (Armv7+)
  WITHOUT_HIGHWAY="true" \
  MESON="--cross-file=/root/meson.ini"

COPY Toolchain.cmake /root/
COPY meson.ini /root/
