FROM debian:bullseye
LABEL maintainer="Lovell Fuller <npm@lovell.info>"

# Create Debian 11 (glibc 2.31) container suitable for cross-compiling Linux ppc64le binaries

# Path settings
ENV \
  RUSTUP_HOME="/usr/local/rustup" \
  CARGO_HOME="/usr/local/cargo" \
  PATH="/usr/local/cargo/bin:$PATH"

# Build dependencies
RUN \
  apt-get update && \
  apt-get install -y curl && \
  dpkg --add-architecture ppc64el && \
  apt-get install -y \
    autoconf \
    autopoint \
    cmake \
    crossbuild-essential-ppc64el \
    gettext \
    git \
    gperf \
    jq \
    libssl-dev \
    libtool \
    ninja-build \
    pkg-config \
    python3-packaging \
    python3-pip \
    && \
  curl https://sh.rustup.rs -sSf | sh -s -- -y \
    --no-modify-path \
    --profile minimal \
    && \
  rustup target add powerpc64le-unknown-linux-gnu && \
  cargo install cargo-c --locked && \
  pip3 install meson tomli

# Handy for debugging the compiled targets in Highway (hwy_list_targets)
#RUN apt-get install -y qemu-user-static
#ENV QEMU_LD_PREFIX="/usr/powerpc64le-linux-gnu"

# Compiler settings
ENV \
  PKG_CONFIG="powerpc64le-linux-gnu-pkg-config --static" \
  PLATFORM="linux-ppc64le" \
  CHOST="powerpc64le-linux-gnu" \
  RUST_TARGET="powerpc64le-unknown-linux-gnu" \
  FLAGS="" \
  MESON="--cross-file=/root/meson.ini"

COPY Toolchain.cmake /root/
COPY meson.ini /root/
