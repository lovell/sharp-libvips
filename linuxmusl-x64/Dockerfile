FROM alpine:3.11
LABEL maintainer="Lovell Fuller <npm@lovell.info>"

# Create Alpine 3.11 (musl 1.1.24) container suitable for building Linux x64 binaries

# Build dependencies
RUN \
  apk update && apk upgrade && \
  apk --update --no-cache add \
    build-base curl git autoconf automake libtool intltool shared-mime-info nasm gtk-doc \
    texinfo gperf glib-dev gobject-introspection-dev findutils jq linux-headers cmake binutils python3 ninja patchelf && \
  apk --update --no-cache --repository https://alpine.global.ssl.fastly.net/alpine/edge/community/ add advancecomp && \
  curl https://sh.rustup.rs -sSf | sh -s -- -y && \
  pip3 install meson

# Compiler settings
ENV \
  PATH="/root/.cargo/bin:$PATH" \
  PLATFORM="linuxmusl-x64" \
  FLAGS="-s -O3 -fPIC"

# Musl defaults to static libs but we need them to be dynamic for host toolchain.
# The toolchain will produce static libs by default.
ENV \
  RUSTFLAGS="-C target-feature=-crt-static"

COPY Toolchain.cmake /root/
