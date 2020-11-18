FROM alpine:3.11
LABEL maintainer="Lovell Fuller <npm@lovell.info>"

# Create Alpine 3.11 (musl 1.1.24) container suitable for building Linux x64 binaries

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
    shared-mime-info \
    texinfo \
    && \
  apk --update --no-cache --repository https://alpine.global.ssl.fastly.net/alpine/edge/community/ add advancecomp && \
  curl https://sh.rustup.rs -sSf | sh -s -- -y \
    --no-modify-path \
    --profile minimal \
    && \
  pip3 install meson==0.55.3

# Compiler settings
ENV \
  PLATFORM="linuxmusl-x64" \
  FLAGS="-O3 -fPIC"

# Musl defaults to static libs but we need them to be dynamic for host toolchain.
# The toolchain will produce static libs by default.
ENV \
  RUSTFLAGS="-C target-feature=-crt-static"

COPY Toolchain.cmake /root/
