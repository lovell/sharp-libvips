FROM debian:bullseye
LABEL maintainer="Lovell Fuller <npm@lovell.info>"

# Create Debian-based container suitable for cross-compiling Linux ARM64v8-A binaries

# Build dependencies
RUN \
  apt-get update && \
  apt-get install -y curl && \
  dpkg --add-architecture arm64 && \
  apt-get update && \
  apt-get install -y crossbuild-essential-arm64 autoconf libtool nasm gtk-doc-tools texinfo gperf advancecomp libglib2.0-dev jq gettext intltool autopoint cmake python3-pip ninja-build patchelf && \
  curl https://sh.rustup.rs -sSf | sh -s -- -y && \
  ~/.cargo/bin/rustup target add aarch64-unknown-linux-gnu && \
  pip3 install meson

# Compiler settings
ENV \
  PATH="/root/.cargo/bin:$PATH" \
  PLATFORM="linux-arm64v8" \
  CHOST="aarch64-linux-gnu" \
  FLAGS="-march=armv8-a -Os -D_GLIBCXX_USE_CXX11_ABI=0" \
  MESON="--cross-file=/root/meson.ini"

COPY Toolchain.cmake /root/
COPY meson.ini /root/
