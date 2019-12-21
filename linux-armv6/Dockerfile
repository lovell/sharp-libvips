FROM debian:stretch
MAINTAINER Lovell Fuller <npm@lovell.info>

# Create Debian-based container suitable for cross-compiling Linux ARMv6 binaries

# Build dependencies
RUN \
  apt-get update && \
  apt-get install -y curl && \
  dpkg --add-architecture armhf && \
  apt-get update && \
  apt-get install -y autoconf libtool nasm gtk-doc-tools texinfo gperf advancecomp libglib2.0-dev jq gettext intltool autopoint cmake python3-pip ninja-build patchelf && \
  mkdir /root/tools && \
  curl -Ls https://github.com/rvagg/rpi-newer-crosstools/archive/master.tar.gz | tar xzC /root/tools --strip-components=1 && \
  curl https://sh.rustup.rs -sSf | sh -s -- -y && \
  ~/.cargo/bin/rustup target add arm-unknown-linux-gnueabihf && \
  pip3 install meson

# Compiler settings
ENV \
  PATH="/root/.cargo/bin:/root/tools/x64-gcc-6.5.0/arm-rpi-linux-gnueabihf/bin:$PATH" \
  PLATFORM="linux-armv6" \
  CHOST="arm-rpi-linux-gnueabihf" \
  RUST_TARGET="arm-unknown-linux-gnueabihf" \
  FLAGS="-marm -mcpu=arm1176jzf-s -mfpu=vfp -mfloat-abi=hard -Os -D_GLIBCXX_USE_CXX11_ABI=0" \
  MESON="--cross-file=/root/meson.ini"

COPY Toolchain.cmake /root/
COPY meson.ini /root/
