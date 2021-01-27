#!/usr/bin/env bash
set -e

if [ $# -lt 1 ]; then
  echo
  echo "Usage: $0 VERSION [PLATFORM]"
  echo "Build shared libraries for libvips and its dependencies via containers"
  echo
  echo "Please specify the libvips VERSION, e.g. 8.9.2"
  echo
  echo "Optionally build for only one PLATFORM, defaults to building for all"
  echo
  echo "Possible values for PLATFORM are:"
  echo "- win32-ia32"
  echo "- win32-x64"
  echo "- win32-arm64v8"
  echo "- linux-x64"
  echo "- linuxmusl-x64"
  echo "- linux-armv6"
  echo "- linux-armv7"
  echo "- linux-arm64v8"
  echo "- darwin-x64"
  echo "- darwin-arm64v8"
  echo
  exit 1
fi
VERSION_VIPS="$1"
PLATFORM="${2:-all}"

# macOS
# Note: we intentionally don't build these binaries inside a Docker container
for flavour in darwin-x64 darwin-arm64v8; do
  if [ $PLATFORM = $flavour ] && [ "$(uname)" == "Darwin" ]; then
    echo "Building $flavour..."

    # Use Clang provided by XCode
    export CC="clang"
    export CXX="clang++"

    export VERSION_VIPS
    export PLATFORM

    # 10.9 should be a good minimal release target
    export MACOSX_DEPLOYMENT_TARGET="10.9"

    # Added -fno-stack-check to workaround a stack misalignment bug on macOS 10.15
    # See:
    # https://forums.developer.apple.com/thread/121887
    # https://trac.ffmpeg.org/ticket/8073#comment:12
    export FLAGS="-O3 -fPIC -fno-stack-check"

    if [ $PLATFORM = "darwin-arm64v8" ]; then
      # ARM64 builds work via cross compilation from an x86_64 machine
      export CHOST="aarch64-apple-darwin"
      export FLAGS+=" -arch arm64"
      export MESON="--cross-file=$PWD/$PLATFORM/meson.ini"
      # macOS 11 Big Sur is the first version to support ARM-based macs
      export MACOSX_DEPLOYMENT_TARGET="11.0"
      # Set SDKROOT to the latest SDK available
      export SDKROOT=$(xcrun -sdk macosx --show-sdk-path)
    fi

    . $PWD/build/mac.sh

    exit 0
  fi
done

# Is docker available?
if ! [ -x "$(command -v docker)" ]; then
  echo "Please install docker"
  exit 1
fi

# Update base images
for baseimage in centos:7 debian:buster debian:bullseye alpine:3.11; do
  docker pull $baseimage
done

# Windows
for flavour in win32-ia32 win32-x64 win32-arm64v8; do
  if [ $PLATFORM = "all" ] || [ $PLATFORM = $flavour ]; then
    echo "Building $flavour..."
    docker build -t vips-dev-win32 win32
    docker run --rm -e "VERSION_VIPS=${VERSION_VIPS}" -e "PLATFORM=${flavour}" -v $PWD:/packaging vips-dev-win32 sh -c "/packaging/build/win.sh"
  fi
done

# Linux (x64, ARMv6, ARMv7, ARM64v8)
for flavour in linux-x64 linuxmusl-x64 linux-armv6 linux-armv7 linux-arm64v8; do
  if [ $PLATFORM = "all" ] || [ $PLATFORM = $flavour ]; then
    echo "Building $flavour..."
    docker build -t vips-dev-$flavour $flavour
    docker run --rm -e "VERSION_VIPS=${VERSION_VIPS}" -v $PWD:/packaging vips-dev-$flavour sh -c "/packaging/build/lin.sh"
  fi
done

# Display checksums
sha256sum *.tar.{br,gz}
