FROM debian:bookworm
LABEL maintainer="Lovell Fuller <npm@lovell.info>"

# Create Debian 12 (glibc 2.36) container suitable for cross-compiling Linux s390x binaries

# Path settings
ENV \
  RUSTUP_HOME="/usr/local/rustup" \
  CARGO_HOME="/usr/local/cargo" \
  PATH="/usr/local/cargo/bin:/root/.local/bin:$PATH"

# Build dependencies
RUN \
  apt-get update && \
  apt-get install -y curl && \
  dpkg --add-architecture s390x && \
  apt-get update && \
  apt-get install -y \
    autoconf \
    autopoint \
    cmake \
    crossbuild-essential-s390x \
    gettext \
    git \
    gperf \
    jq \
    libssl-dev \
    libtool \
    ninja-build \
    pipx \
    pkgconf \
    pkgconf:s390x \
    && \
  curl https://sh.rustup.rs -sSf | sh -s -- -y \
    --no-modify-path \
    --profile minimal \
    --target s390x-unknown-linux-gnu \
    --default-toolchain nightly \
    && \
  cargo install cargo-c --locked && \
  pipx install meson

# Handy for debugging the compiled targets in Highway (hwy_list_targets)
#RUN apt-get install -y qemu-user-static
#ENV QEMU_LD_PREFIX="/usr/s390x-linux-gnu"

# Compiler settings
ENV \
  PKG_CONFIG="s390x-linux-gnu-pkg-config --static" \
  PLATFORM="linux-s390x" \
  CHOST="s390x-linux-gnu" \
  RUST_TARGET="s390x-unknown-linux-gnu" \
  FLAGS="" \
  RUSTFLAGS="-Zlocation-detail=none -Zfmt-debug=none" \
  # Highway requires IBM z14, which isn't the baseline in
  # Debian yet. Therefore, it should remain disabled for now.
  #FLAGS="-march=z14 -mzvector" \
  WITHOUT_HIGHWAY="true" \
  MESON="--cross-file=/root/meson.ini"

COPY Toolchain.cmake /root/
COPY meson.ini /root/
