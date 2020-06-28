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
    brotli \
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
    python3-pip \
    texinfo \
    && \
  curl https://sh.rustup.rs -sSf | sh -s -- -y && \
  # Downgrade to 1.43.0, see: https://github.com/rust-lang/compiler-builtins/issues/353
  ~/.cargo/bin/rustup toolchain install 1.43.0 && ~/.cargo/bin/rustup default 1.43.0 && \
  ~/.cargo/bin/rustup target add arm-unknown-linux-gnueabihf && \
  pip3 install meson

# Compiler settings
ENV \
  PATH="/root/.cargo/bin:$PATH" \
  PKG_CONFIG="/usr/bin/arm-linux-gnueabihf-pkg-config" \
  PLATFORM="linux-armv7" \
  CHOST="arm-linux-gnueabihf" \
  RUST_TARGET="arm-unknown-linux-gnueabihf" \
  FLAGS="-marm -march=armv7-a -mfpu=neon-vfpv4 -mfloat-abi=hard -O3 -fPIC -D_GLIBCXX_USE_CXX11_ABI=0" \
  MESON="--cross-file=/root/meson.ini"

COPY Toolchain.cmake /root/
COPY meson.ini /root/
