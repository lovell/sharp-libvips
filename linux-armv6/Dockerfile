FROM debian:buster
MAINTAINER Lovell Fuller <npm@lovell.info>

# Create Debian-based container suitable for cross-compiling Linux ARMv6 binaries

# Build dependencies
RUN \
  apt-get update && \
  apt-get install -y curl && \
  dpkg --add-architecture armhf && \
  apt-get update && \
  apt-get install -y crossbuild-essential-armhf autoconf libtool nasm gtk-doc-tools texinfo gperf advancecomp libglib2.0-dev jq gettext intltool autopoint && \
  curl https://sh.rustup.rs -sSf | sh -s -- -y && \
  ~/.cargo/bin/rustup target add arm-unknown-linux-gnueabihf

# Compiler settings
ENV \
  PATH="/root/.cargo/bin:$PATH" \
  PLATFORM="linux-armv6" \
  CHOST="arm-linux-gnueabihf" \
  FLAGS="-marm -mcpu=arm1176jzf-s -mfpu=vfp -mfloat-abi=hard -Os -D_GLIBCXX_USE_CXX11_ABI=0"
