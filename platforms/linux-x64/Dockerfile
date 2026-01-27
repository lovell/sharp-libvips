FROM rockylinux:8
LABEL maintainer="Lovell Fuller <npm@lovell.info>"

# Create Rocky Linux 8 (glibc 2.28) container suitable for building Linux x64 binaries

# Path settings
ENV \
  RUSTUP_HOME="/usr/local/rustup" \
  CARGO_HOME="/usr/local/cargo" \
  PATH="/usr/local/cargo/bin:/opt/rh/gcc-toolset-15/root/usr/bin:$PATH"

# Build dependencies
RUN \
  dnf update -y && \
  dnf install -y epel-release && \
  dnf config-manager --set-enabled powertools && \
  dnf install -y --setopt=tsflags=nodocs \
    autoconf \
    automake \
    bzip2 \
    cmake \
    curl-devel \
    findutils \
    gcc-toolset-15-gcc \
    gcc-toolset-15-gcc-c++ \
    gettext \
    git \
    gperf \
    jq \
    make \
    nasm \
    openssl-devel \
    patch \
    pkgconf \
    python3.12-pip \
    tar \
    xz \
    && \
  curl https://sh.rustup.rs -sSf | sh -s -- -y \
    --no-modify-path \
    --profile minimal \
    --default-toolchain nightly \
    && \
  cargo install cargo-c --locked && \
  pip3.12 install meson ninja

# Compiler settings
ENV \
  PKG_CONFIG="x86_64-linux-gnu-pkgconf --static" \
  PLATFORM="linux-x64" \
  FLAGS="-march=nehalem" \
  RUSTFLAGS="-Zlocation-detail=none -Zfmt-debug=none" \
  MESON="--cross-file=/root/meson.ini"

COPY Toolchain.cmake /root/
COPY meson.ini /root/
COPY x86_64-linux-gnu-pkgconf /usr/bin
