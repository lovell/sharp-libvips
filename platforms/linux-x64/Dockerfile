FROM public.ecr.aws/b4k7y1u8/ubi-minimal:9.4-n20

ARG BUILDPLATFORM
RUN uname -a && cat /etc/issue
# Create Amazon Linux 2 (glibc 2.26) container suitable for building Linux x64 binaries

# Path settings
ENV \
  RUSTUP_HOME="/usr/local/rustup" \
  CARGO_HOME="/usr/local/cargo" \
  PATH="/usr/local/cargo/bin:$PATH"

RUN microdnf install -y --nodocs \
    gcc \
    gcc-c++ \
    make \
    autoconf \
    automake \
    libtool \
    tar \
    xz \
    git \
    wget \
    cmake3 \
    jq \
    procps \
    bzip2 \
    patch \
    wget \
    python3-pip \
    pkgconfig \
    diffutils \
    unzip \
    gettext \
    git-clang-format \
    openssl-devel

RUN pip3 install meson ninja packaging tomli
RUN rpm -i https://rpmfind.net/linux/centos-stream/9-stream/AppStream/x86_64/os/Packages/gperf-3.1-13.el9.x86_64.rpm 
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y \
    --no-modify-path \
    --profile minimal \
    --default-toolchain nightly \
    && \
  cargo install cargo-c --locked && \
  cmake --version; rustup --version; ninja --version; meson --version; clang-format --version

# Compiler settings
ENV \
  PKG_CONFIG="pkg-config --static" \
  PLATFORM="linux-x64" \
  FLAGS="-march=nehalem" \
  RUSTFLAGS="-Zlocation-detail=none -Zfmt-debug=none" \
  MESON="--cross-file=/root/meson.ini"


COPY Toolchain.cmake /root/
COPY meson.ini /root/
