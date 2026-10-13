#!/usr/bin/env bash
set -e

## SPDX-FileCopyrightText: 2017 Lovell Fuller and others
## SPDX-License-Identifier: Apache-2.0

source ./versions.properties
VERSION_WASM_VIPS="${1:-master}"

DIR="wasm-vips-${VERSION_WASM_VIPS}"
TAG="wasm-vips:${VERSION_WASM_VIPS}"

echo "Using ${TAG} to build libvips ${VERSION_VIPS}"
cd "${0%/*}"

# Clone a specific version of wasm-vips
if [ ! -d "$DIR" ]; then
  git clone -b ${VERSION_WASM_VIPS} --depth 1 https://github.com/kleisauke/wasm-vips.git "${DIR}"
fi

# Check libvips versions match
VERSION_VIPS_UPSTREAM=$(grep -Po "^VERSION_VIPS=\K[^ ]*" "${DIR}/build.sh")
if [ "$VERSION_VIPS" != "$VERSION_VIPS_UPSTREAM" ]; then
  echo "Expected libvips $VERSION_VIPS, found $VERSION_VIPS_UPSTREAM upstream" # TODO: modify build.sh on-the-fly?
  exit 1
fi

# Create container with emscripten
pushd "${DIR}"
docker build -t "${TAG}" .
popd

# Build libvips and dependencies as static Wasm libraries via emscripten
if [ ! -d "$DIR/build/target/lib" ]; then
  docker run --rm -v "$PWD/${DIR}":/src "${TAG}" -c "./build.sh --disable-bindings --disable-modules --disable-jxl --enable-libvips-cpp"
else
  echo "Skipping build: found existing files in $DIR/build/target"
fi

echo "Creating tarball"
tar chzf \
  ../sharp-libvips-dev-wasm32.tar.gz \
  --directory="${DIR}/build/target" \
  --exclude="cmake/*" \
  --hard-dereference \
  {include,lib,versions.json}
