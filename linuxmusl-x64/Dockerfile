FROM alpine:3.10
MAINTAINER Lovell Fuller <npm@lovell.info>

# Create Alpine 3.10 (musl 1.1.22) container suitable for building Linux x64 binaries

# Build dependencies
RUN \
  apk update && apk upgrade && \
  apk --update --no-cache add \
    build-base curl git autoconf automake libtool intltool shared-mime-info nasm gtk-doc \
    texinfo gperf glib-dev gobject-introspection-dev findutils jq linux-headers cmake && \
  apk --update --no-cache --repository https://alpine.global.ssl.fastly.net/alpine/edge/community/ add cargo && \
  apk --update --no-cache --repository https://alpine.global.ssl.fastly.net/alpine/edge/testing/ add advancecomp

# Compiler settings
ENV \
  PLATFORM="linuxmusl-x64" \
  FLAGS="-O3"

COPY Toolchain.cmake /root/
