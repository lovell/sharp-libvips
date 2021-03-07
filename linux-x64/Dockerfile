FROM centos:7
LABEL maintainer="Lovell Fuller <npm@lovell.info>"

# Create CentOS 7 (glibc 2.17) container suitable for building Linux x64 binaries

# Path settings
ENV \
  RUSTUP_HOME="/usr/local/rustup" \
  CARGO_HOME="/usr/local/cargo" \
  PATH="/usr/local/cargo/bin:/opt/rh/devtoolset-10/root/usr/bin:$PATH"

# Build dependencies
RUN \
  yum update -y && \
  yum install -y epel-release centos-release-scl && \
  yum group install -y "Development Tools" && \
  yum install -y --setopt=tsflags=nodocs \
    advancecomp \
    brotli \
    cmake3 \
    devtoolset-10-gcc \
    devtoolset-10-gcc-c++ \
    glib2-devel \
    gobject-introspection-devel \
    gperf \
    gtk-doc \
    jq \
    nasm \
    ninja-build \
    prelink \
    python3 \
    && \
  yum install -y https://www.nasm.us/pub/nasm/releasebuilds/2.14.02/linux/nasm-2.14.02-0.fc27.x86_64.rpm && \
  curl https://sh.rustup.rs -sSf | sh -s -- -y \
    --no-modify-path \
    --profile minimal \
    && \
  ln -s /usr/bin/cmake3 /usr/bin/cmake && \
  pip3 install meson

# Compiler settings
ENV \
  PLATFORM="linux-x64" \
  FLAGS="-march=westmere" \
  MESON="--cross-file=/root/meson.ini"

COPY Toolchain.cmake /root/
COPY meson.ini /root/
