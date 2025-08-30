FROM debian:bookworm
LABEL maintainer="Lovell Fuller <npm@lovell.info>"

# Create Debian 12 (glibc 2.36) container suitable for cross-compiling Linux ppc64le binaries

# Path settings
ENV \
  RUSTUP_HOME="/usr/local/rustup" \
  CARGO_HOME="/usr/local/cargo" \
  PATH="/usr/local/cargo/bin:/root/.local/bin:$PATH"

# Build dependencies
RUN \
  apt-get update && \
  apt-get install -y curl && \
  dpkg --add-architecture ppc64el && \
  apt-get update && \
  apt-get install -y \
    autoconf \
    autopoint \
    cmake \
    crossbuild-essential-ppc64el \
    gettext \
    git \
    gperf \
    jq \
    libssl-dev \
    libtool \
    ninja-build \
    pipx \
    pkgconf \
    pkgconf:ppc64el \
    && \
  curl https://sh.rustup.rs -sSf | sh -s -- -y \
    --no-modify-path \
    --profile minimal \
    --target powerpc64le-unknown-linux-gnu \
    --default-toolchain nightly \
    && \
  cargo install cargo-c --locked && \
  pipx install meson

# Handy for debugging the compiled targets in Highway (hwy_list_targets)
#RUN apt-get install -y qemu-user-static
#ENV QEMU_LD_PREFIX="/usr/powerpc64le-linux-gnu"

# Compiler settings
ENV \
  PKG_CONFIG="powerpc64le-linux-gnu-pkg-config --static" \
  PLATFORM="linux-ppc64le" \
  CHOST="powerpc64le-linux-gnu" \
  RUST_TARGET="powerpc64le-unknown-linux-gnu" \
  FLAGS="" \
  RUSTFLAGS="-Zlocation-detail=none -Zfmt-debug=none" \
  MESON="--cross-file=/root/meson.ini"

COPY Toolchain.cmake /root/
COPY meson.ini /root/
