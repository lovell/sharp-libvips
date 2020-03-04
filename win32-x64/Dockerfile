FROM debian:buster
LABEL maintainer="Lovell Fuller <npm@lovell.info>"

# Create Debian-based container suitable for post-processing 64-bit Windows binaries

RUN apt-get update && apt-get install -y curl zip advancecomp

ENV PLATFORM="win32-x64"
