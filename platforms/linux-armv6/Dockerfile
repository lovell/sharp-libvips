FROM debian/eol:buster
LABEL maintainer="Lovell Fuller <npm@lovell.info>"

# Create Debian 11 (glibc 2.31) container suitable for cross-compiling Linux ARMv6 binaries

# Path settings
ENV \
  RUSTUP_HOME="/usr/local/rustup" \
  CARGO_HOME="/usr/local/cargo" \
  PATH="/usr/local/cargo/bin:/root/tools/x64-gcc-10.3.0-glibc-2.28/arm-rpi-linux-gnueabihf/bin:$PATH"

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
    libssl-dev \
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
    --target arm-unknown-linux-gnueabihf \
    --default-toolchain nightly \
    && \
  cargo install cargo-c --locked && \
  pip3 install meson tomli

# Compiler settings
ENV \
  PKG_CONFIG="arm-linux-gnueabihf-pkg-config --static" \
  PLATFORM="linux-armv6" \
  CHOST="arm-rpi-linux-gnueabihf" \
  RUST_TARGET="arm-unknown-linux-gnueabihf" \
  FLAGS="-marm -mcpu=arm1176jzf-s -mfpu=vfp -mfloat-abi=hard" \
  RUSTFLAGS="-Zlocation-detail=none -Zfmt-debug=none" \
  WITHOUT_NEON="true" \
  # Highway requires NEON (Armv7+)
  WITHOUT_HIGHWAY="true" \
  MESON="--cross-file=/root/meson.ini"

COPY Toolchain.cmake /root/
COPY meson.ini /root/
