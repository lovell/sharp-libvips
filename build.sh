#!/usr/bin/env bash
set -e

# Dependency version numbers
source ./versions.properties

if [ $# -lt 1 ]; then
  echo
  echo "Usage: $0 PLATFORM"
  echo "Build shared libraries for libvips and its dependencies"
  echo
  echo "Possible values for PLATFORM are:"
  echo "- win32-ia32"
  echo "- win32-x64"
  echo "- win32-arm64v8"
  echo "- linux-x64"
  echo "- linuxmusl-x64"
  echo "- linux-armv6"
  echo "- linux-arm64v8"
  echo "- linuxmusl-arm64v8"
  echo "- linux-ppc64le"
  echo "- linux-riscv64"
  echo "- linux-s390x"
  echo "- darwin-x64"
  echo "- darwin-arm64v8"
  echo "- dev-wasm32"
  echo
  exit 1
fi
PLATFORM="$1"

# macOS
# Note: we intentionally don't build these binaries inside a Docker container
for flavour in darwin-x64 darwin-arm64v8; do
  if [ $PLATFORM = $flavour ] && [ "$(uname)" == "Darwin" ]; then
    echo "Building $flavour..."

    # Use Clang provided by XCode
    export CC="clang"
    export CXX="clang++"

    export PLATFORM

    # Use pkg-config provided by Homebrew
    export PKG_CONFIG="$(brew --prefix)/bin/pkg-config --static"

    # Earliest supported version of macOS
    if [ $PLATFORM = "darwin-arm64v8" ]; then
      export MACOSX_DEPLOYMENT_TARGET="11.0"
    else
      export MACOSX_DEPLOYMENT_TARGET="10.15"
    fi

    # Added -fno-stack-check to workaround a stack misalignment bug on macOS 10.15
    # See:
    # https://forums.developer.apple.com/thread/121887
    # https://trac.ffmpeg.org/ticket/8073#comment:12
    export FLAGS="-fno-stack-check"
    # Prevent use of API newer than the deployment target
    export FLAGS+=" -Werror=unguarded-availability-new"
    export MESON="--cross-file=$PWD/platforms/$PLATFORM/meson.ini"

    source $PWD/versions.properties
    source $PWD/build/posix.sh

    exit 0
  fi
done

# Is docker available?
if ! [ -x "$(command -v docker)" ]; then
  echo "Please install docker"
  exit 1
fi

# WebAssembly
if [ "$PLATFORM" == "dev-wasm32" ]; then
  ./build/wasm.sh
  exit 0
fi

# Windows
for flavour in win32-ia32 win32-x64 win32-arm64v8; do
  if [ $PLATFORM = "all" ] || [ $PLATFORM = $flavour ]; then
    echo "Building $flavour..."
    docker build --pull -t vips-dev-win32 platforms/win32
    docker run --rm -e "PLATFORM=${flavour}" -v $PWD:/packaging vips-dev-win32 sh -c "/packaging/build/win.sh"
  fi
done

# Linux (x64, ARMv6, ARM64v8)
for flavour in linux-x64 linuxmusl-x64 linux-armv6 linux-arm64v8 linuxmusl-arm64v8 linux-ppc64le linux-riscv64 linux-s390x; do
  if [ $PLATFORM = "all" ] || [ $PLATFORM = $flavour ]; then
    echo "Building $flavour..."
    docker build --pull -t vips-dev-$flavour platforms/$flavour
    docker run --rm -v $PWD:/packaging vips-dev-$flavour sh -c "/packaging/build/posix.sh"
  fi
done
