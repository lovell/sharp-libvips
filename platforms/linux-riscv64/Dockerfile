FROM debian:trixie
LABEL maintainer="Lovell Fuller <npm@lovell.info>"

# Create Debian 13 (glibc 2.41) container suitable for cross-compiling Linux RISC-V 64-bit binaries

# Path settings
ENV \
  RUSTUP_HOME="/usr/local/rustup" \
  CARGO_HOME="/usr/local/cargo" \
  PATH="/usr/local/cargo/bin:/root/.local/bin:$PATH"

# Build dependencies
RUN \
  apt-get update && \
  apt-get install -y curl && \
  dpkg --add-architecture riscv64 && \
  apt-get update && \
  apt-get install -y \
    autoconf \
    autopoint \
    cmake \
    crossbuild-essential-riscv64 \
    gettext \
    git \
    gperf \
    jq \
    libssl-dev \
    libtool \
    ninja-build \
    pipx \
    pkgconf \
    pkgconf:riscv64 \
    && \
  curl https://sh.rustup.rs -sSf | sh -s -- -y \
    --no-modify-path \
    --profile minimal \
    --target riscv64gc-unknown-linux-gnu \
    --default-toolchain nightly \
    && \
  cargo install cargo-c --locked && \
  pipx install meson

# Compiler settings
ENV \
  PKG_CONFIG="riscv64-linux-gnu-pkg-config --static" \
  PLATFORM="linux-riscv64" \
  CHOST="riscv64-linux-gnu" \
  RUST_TARGET="riscv64gc-unknown-linux-gnu" \
  FLAGS="-march=rv64gc" \
  RUSTFLAGS="-Zlocation-detail=none -Zfmt-debug=none" \
  # Highway requires RVV version 1.0, which isn't the baseline
  # in Debian yet. Therefore, it should remain disabled for now.
  #FLAGS="-march=rv64gcv1p0 -menable-experimental-extensions" \
  WITHOUT_HIGHWAY="true" \
  MESON="--cross-file=/root/meson.ini"

COPY Toolchain.cmake /root/
COPY meson.ini /root/
