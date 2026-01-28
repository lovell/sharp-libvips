FROM alpine:3.20
LABEL maintainer="Lovell Fuller <npm@lovell.info>"

# Create Alpine 3.20 (musl 1.2.5) container suitable for building musl-based Linux x64 binaries

# Path settings
ENV \
  RUSTUP_HOME="/usr/local/rustup" \
  CARGO_HOME="/usr/local/cargo" \
  PATH="/usr/local/cargo/bin:/root/.local/bin:$PATH"

# Musl defaults to static libs but we need them to be dynamic for host toolchain.
# The toolchain will produce static libs by default.
ENV \
  RUSTFLAGS="-Ctarget-feature=-crt-static"

# Build dependencies
RUN \
  apk update && apk upgrade && \
  apk --update --no-cache add \
    autoconf \
    automake \
    bash \
    binutils \
    build-base \
    cmake \
    coreutils \
    curl \
    curl-dev \
    findutils \
    git \
    gperf \
    jq \
    libtool \
    linux-headers \
    nasm \
    ninja \
    openssl-dev \
    pipx \
    pkgconf \
    && \
  curl https://sh.rustup.rs -sSf | sh -s -- -y \
    --no-modify-path \
    --profile minimal \
    --default-toolchain nightly \
    && \
  cargo install cargo-c --locked && \
  pipx install meson

# Compiler settings
ENV \
  PKG_CONFIG="pkg-config --static" \
  PLATFORM="linuxmusl-x64" \
  FLAGS="-march=nehalem" \
  RUSTFLAGS="-Zlocation-detail=none -Zfmt-debug=none" \
  MESON="--cross-file=/root/meson.ini"

COPY Toolchain.cmake /root/
COPY meson.ini /root/
