FROM alpine:3.11
LABEL maintainer="Lovell Fuller <npm@lovell.info>"

# Create Alpine 3.11 (musl 1.1.24) container suitable for building Linux x64 binaries

# Build dependencies
RUN \
  apk update && apk upgrade && \
  apk --update --no-cache add \
    build-base curl git autoconf automake libtool intltool shared-mime-info nasm gtk-doc \
    texinfo gperf glib-dev gobject-introspection-dev findutils jq linux-headers cmake binutils python3 ninja patchelf && \
  apk --update --no-cache --repository https://alpine.global.ssl.fastly.net/alpine/v3.11/community/ add cargo && \
  apk --update --no-cache --repository https://alpine.global.ssl.fastly.net/alpine/edge/testing/ add advancecomp && \
  pip3 install meson

# Compiler settings
ENV \
  PLATFORM="linuxmusl-x64" \
  FLAGS="-O3"

COPY Toolchain.cmake /root/
