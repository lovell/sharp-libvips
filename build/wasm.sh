#!/usr/bin/env bash
set -e

source ./versions.properties
VERSION_WASM_VIPS="${1:-HEAD}"

DIR="wasm-vips-${VERSION_WASM_VIPS}"
TAG="wasm-vips:${VERSION_WASM_VIPS}"

echo "Using ${TAG} to build libvips ${VERSION_VIPS}"
cd "${0%/*}"

# Download specific version of wasm-vips
if [ ! -d "$DIR" ]; then
  mkdir "${DIR}"
  curl -Ls https://github.com/kleisauke/wasm-vips/archive/${VERSION_WASM_VIPS}.tar.gz | tar xzC "${DIR}" --strip-components=1
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
  {include,lib,versions.json}
