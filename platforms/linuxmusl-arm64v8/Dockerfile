FROM alpine:3.15
LABEL maintainer="Lovell Fuller <npm@lovell.info>"

# Create Alpine 3.15 (musl 1.2.2) container suitable for cross-compiling musl-based Linux ARM64v8-A binaries

# Path settings
ENV \
  RUSTUP_HOME="/usr/local/rustup" \
  CARGO_HOME="/usr/local/cargo" \
  PATH="/usr/local/cargo/bin:$PATH"

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
    coreutils \
    curl \
    findutils \
    git \
    gperf \
    jq \
    libtool \
    linux-headers \
    ninja \
    pkgconf \
    py3-pip \
    python3 \
    && \
  apk --update --no-cache --repository https://alpine.global.ssl.fastly.net/alpine/v3.17/community/ add advancecomp && \
  curl -Ls https://github.com/lovell/aarch64-linux-musl-crosstools/archive/main.tar.gz | tar -hxzC / --strip-components=2 && \
  ln -s /usr/bin/pkg-config /bin/aarch64-linux-musl-pkg-config && \
  curl https://sh.rustup.rs -sSf | sh -s -- -y \
    --no-modify-path \
    --profile minimal \
    && \
  rustup target add aarch64-unknown-linux-musl && \
  pip3 install meson

# Compiler settings
ENV \
  PKG_CONFIG="aarch64-linux-musl-pkg-config --static" \
  PLATFORM="linuxmusl-arm64v8" \
  CHOST="aarch64-linux-musl" \
  RUST_TARGET="aarch64-unknown-linux-musl" \
  FLAGS="-march=armv8-a" \
  MESON="--cross-file=/root/meson.ini"

# Musl defaults to static libs but we need them to be dynamic for host toolchain.
# The toolchain will produce static libs by default.
# We also need to add the directory containing libc.a to the library search path.
ENV \
  RUSTFLAGS="-Ctarget-feature=-crt-static -Lnative=/aarch64-linux-musl/lib"

COPY Toolchain.cmake /root/
COPY meson.ini /root/
