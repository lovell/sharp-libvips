FROM alpine:3.11
LABEL maintainer="Lovell Fuller <npm@lovell.info>"

# Create Alpine 3.11 (musl 1.1.24) container suitable for cross-compiling musl-based Linux ARM64v8-A binaries

# Path settings
ENV \
  RUSTUP_HOME="/usr/local/rustup" \
  CARGO_HOME="/usr/local/cargo" \
  PATH="/usr/local/cargo/bin:/root/tools/aarch64-linux-musl-cross/bin:$PATH"

# Build dependencies
RUN \
  apk update && apk upgrade && \
  apk --update --no-cache add \
    autoconf \
    automake \
    binutils \
    brotli \
    build-base \
    cmake \
    curl \
    findutils \
    git \
    glib-dev \
    gobject-introspection-dev \
    gperf \
    gtk-doc \
    intltool \
    jq \
    libtool \
    linux-headers \
    nasm \
    ninja \
    python3 \
    py3-pip \
    shared-mime-info \
    texinfo \
    && \
  apk --update --no-cache --repository https://alpine.global.ssl.fastly.net/alpine/edge/community/ add advancecomp && \
  mkdir /root/tools && \
  curl -Ls https://github.com/lovell/aarch64-linux-musl-crosstools/archive/main.tar.gz | tar xzC /root/tools --strip-components=1 && \
  ln -s /usr/bin/pkg-config /usr/bin/aarch64-linux-musl-pkg-config && \
  curl https://sh.rustup.rs -sSf | sh -s -- -y \
    --no-modify-path \
    --profile minimal \
    && \
  rustup target add aarch64-unknown-linux-musl && \
  pip3 install meson==0.56.2

# Compiler settings
ENV \
  PKG_CONFIG="/usr/bin/aarch64-linux-musl-pkg-config" \
  PLATFORM="linuxmusl-arm64v8" \
  CHOST="aarch64-linux-musl" \
  RUST_TARGET="aarch64-unknown-linux-musl" \
  FLAGS="-march=armv8-a" \
  MESON="--cross-file=/root/meson.ini"

# Musl defaults to static libs but we need them to be dynamic for host toolchain.
# The toolchain will produce static libs by default.
ENV \
  RUSTFLAGS="-C target-feature=-crt-static"

COPY Toolchain.cmake /root/
COPY meson.ini /root/
