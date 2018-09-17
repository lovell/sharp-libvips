FROM alpine:3.8
MAINTAINER Lovell Fuller <npm@lovell.info>

# Create Alpine 3.8 (musl 1.1.19) container suitable for building Linux x64 binaries

# Build dependencies
RUN \
  apk update && \
  apk upgrade && \
  apk --update --no-cache --repository https://dl-3.alpinelinux.org/alpine/edge/testing/ add \
    build-base curl git autoconf automake libtool intltool shared-mime-info nasm gtk-doc texinfo gperf advancecomp glib-dev gobject-introspection-dev findutils jq cargo

# Compiler settings
# RUST_OPT_LEVEL override can be removed when Alpine 3.9 is minimum supported
ENV \
  PLATFORM="linuxmusl-x64" \
  FLAGS="-O3" \
  RUST_OPT_LEVEL="2"
