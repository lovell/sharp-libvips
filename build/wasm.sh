#!/usr/bin/env bash
set -e

if [ $# -lt 1 ]; then
  echo
  echo "Usage: $0 VERSION_VIPS [VERSION_WASM_VIPS]"
  echo "Use wasm-vips to build wasm32 static libraries for libvips and its dependencies"
  echo
  echo "Please specify the libvips VERSION_VIPS, e.g. 8.15.0"
  echo "Optionally provide a specific VERSION_WASM_VIPS commit, e.g. abc1234"
  echo
  exit 1
fi
VERSION_VIPS="$1"
VERSION_WASM_VIPS="${2:-56f151b}" # TODO: fetch latest wasm-vips commit as default

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
if [ -z "$(docker images -q ${TAG})" ]; then
  pushd "${DIR}"
  docker build -t "${TAG}" .
  popd
fi

# Build libvips and dependencies as static Wasm libraries via emscripten
if [ ! -d "$DIR/build/target/lib" ]; then
  docker run --rm -v "$PWD/${DIR}":/src "${TAG}" -c "./build.sh --disable-bindings --disable-modules --disable-jxl --enable-libvips-cpp"
fi

# Copy only the files we need
cp -r --no-preserve=mode,ownership ${DIR}/build/target/{include,lib,versions.json} ../npm/dev-wasm32
rm -r ../npm/dev-wasm32/lib/cmake
