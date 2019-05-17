FROM debian:jessie
MAINTAINER Lovell Fuller <npm@lovell.info>

# Create Debian 8 (glibc 2.19) container suitable for building Linux x64 binaries

# Build dependencies
RUN \
  apt-get update && \
  apt-get install -y build-essential gcc-4.9 prelink autoconf libtool nasm gtk-doc-tools texinfo gperf advancecomp libglib2.0-dev gobject-introspection jq cmake && \
  curl https://sh.rustup.rs -sSf | sh -s -- -y

# Compiler settings
ENV \
  PATH="/root/.cargo/bin:$PATH" \
  PLATFORM="linux-x64" \
  FLAGS="-O3"

COPY Toolchain.cmake /root/
