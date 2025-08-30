FROM arm64v8/amazonlinux:2
LABEL maintainer="Lovell Fuller <npm@lovell.info>"

# Create Amazon Linux 2 (glibc 2.26) container suitable for building Linux ARM64v8-A binaries

# Path settings
ENV \
  RUSTUP_HOME="/usr/local/rustup" \
  CARGO_HOME="/usr/local/cargo" \
  PATH="/usr/local/cargo/bin:$PATH"

# Build dependencies
RUN \
  yum update -y && \
  amazon-linux-extras install epel -y && \
  yum install -y --setopt=tsflags=nodocs \
    --exclude=gcc \
    autoconf \
    automake \
    bzip2 \
    cmake3 \
    curl \
    gcc10 \
    gcc10-binutils \
    gcc10-c++ \
    gettext \
    git \
    gperf \
    jq \
    make \
    openssl-devel \
    patch \
    pkgconfig \
    python3 \
    tar \
    xz \
    && \
  ln -s /usr/bin/gcc10-gcc /usr/bin/cc && \
  ln -s /usr/bin/gcc10-g++ /usr/bin/c++ && \
  ln -s /usr/bin/gcc10-as /usr/bin/as && \
  ln -s /usr/bin/gcc10-ar /usr/bin/ar && \
  ln -s /usr/bin/gcc10-nm /usr/bin/nm && \
  ln -s /usr/bin/gcc10-ld.bfd /usr/bin/ld && \
  ln -s /usr/bin/gcc10-strip /usr/bin/strip && \
  ln -s /usr/bin/gcc10-ranlib /usr/bin/ranlib && \
  ln -s /usr/bin/gcc10-readelf /usr/bin/readelf && \
  ln -sf /usr/bin/gcc10-ld.bfd /usr/bin/gcc10-ld && \
  rm /usr/bin/gcc10-ld.gold && \
  curl https://sh.rustup.rs -sSf | sh -s -- -y \
    --no-modify-path \
    --profile minimal \
    --default-host aarch64-unknown-linux-gnu \
    --default-toolchain nightly \
    && \
  cargo install cargo-c --locked && \
  ln -s /usr/bin/cmake3 /usr/bin/cmake && \
  pip3 install meson ninja tomli

# Compiler settings
ENV \
  PKG_CONFIG="pkg-config --static" \
  PLATFORM="linux-arm64v8" \
  FLAGS="-march=armv8-a" \
  RUSTFLAGS="-Zlocation-detail=none -Zfmt-debug=none" \
  MESON="--cross-file=/root/meson.ini"

COPY Toolchain.cmake /root/
COPY meson.ini /root/
