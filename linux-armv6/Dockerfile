FROM debian:buster
LABEL maintainer="Lovell Fuller <npm@lovell.info>"

# Create Debian-based container suitable for cross-compiling Linux ARMv6 binaries

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
    advancecomp \
    autoconf \
    autopoint \
    brotli \
    cmake \
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
    python3-pip \
    texinfo \
    && \
  mkdir /root/tools && \
  curl -Ls https://github.com/rvagg/rpi-newer-crosstools/archive/master.tar.gz | tar xzC /root/tools --strip-components=1 && \
  curl https://sh.rustup.rs -sSf | sh -s -- -y \
    --no-modify-path \
    --profile minimal \
    && \
  # Downgrade to 1.43.0, see: https://github.com/rust-lang/compiler-builtins/issues/353
  rustup toolchain install 1.43.0 && rustup default 1.43.0 && \
  rustup target add arm-unknown-linux-gnueabihf && \
  pip3 install meson==0.55.3

# Compiler settings
ENV \
  PKG_CONFIG="/usr/bin/arm-linux-gnueabihf-pkg-config" \
  PLATFORM="linux-armv6" \
  CHOST="arm-rpi-linux-gnueabihf" \
  RUST_TARGET="arm-unknown-linux-gnueabihf" \
  FLAGS="-marm -mcpu=arm1176jzf-s -mfpu=vfp -mfloat-abi=hard -O3 -fPIC -D_GLIBCXX_USE_CXX11_ABI=0" \
  WITHOUT_NEON="true" \
  MESON="--cross-file=/root/meson.ini"

COPY Toolchain.cmake /root/
COPY meson.ini /root/
