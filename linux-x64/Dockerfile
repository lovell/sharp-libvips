FROM centos:7
LABEL maintainer="Lovell Fuller <npm@lovell.info>"

# Create CentOS 7 (glibc 2.17) container suitable for building Linux x64 binaries

# Path settings
ENV \
  RUSTUP_HOME="/usr/local/rustup" \
  CARGO_HOME="/usr/local/cargo" \
  PATH="/usr/local/cargo/bin:/opt/rh/devtoolset-11/root/usr/bin:/opt/rh/rh-python38/root/usr/bin:/opt/rh/rh-python38/root/usr/local/bin:$PATH"

# Build dependencies
RUN \
  yum update -y && \
  yum install -y epel-release centos-release-scl && \
  yum group install -y "Development Tools" && \
  yum install -y --setopt=tsflags=nodocs \
    advancecomp \
    brotli \
    cmake3 \
    devtoolset-11-gcc \
    devtoolset-11-gcc-c++ \
    gperf \
    jq \
    nasm \
    rh-python38 \
    && \
  curl https://sh.rustup.rs -sSf | sh -s -- -y \
    --no-modify-path \
    --profile minimal \
    && \
  ln -s /usr/bin/cmake3 /usr/bin/cmake && \
  pip3 install meson ninja

# Compiler settings
ENV \
  PKG_CONFIG="pkg-config --static" \
  PLATFORM="linux-x64" \
  FLAGS="-march=westmere" \
  MESON="--cross-file=/root/meson.ini"

COPY Toolchain.cmake /root/
COPY meson.ini /root/
