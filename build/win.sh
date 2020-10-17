#!/usr/bin/env bash
set -e

VERSION_VIPS_SHORT=${VERSION_VIPS%.[[:digit:]]*}

# Common options for curl
CURL="curl --silent --location --retry 3 --retry-max-time 30"

# Fetch and unzip
mkdir /vips
cd /vips

if [[ $PLATFORM == "win32-arm64v8" ]]; then
  $CURL -O https://github.com/libvips/build-win64-mxe/releases/download/v${VERSION_VIPS}-build2/vips-dev-arm64-web-${VERSION_VIPS}-static.zip
  unzip vips-dev-arm64-web-${VERSION_VIPS}-static.zip
else
  BITS=${PLATFORM: -2}
  $CURL -O https://github.com/libvips/build-win64-mxe/releases/download/v${VERSION_VIPS}-build2/vips-dev-w${BITS}-web-${VERSION_VIPS}-static.zip
  unzip vips-dev-w${BITS}-web-${VERSION_VIPS}-static.zip
fi

# Clean and zip
cd /vips/vips-dev-${VERSION_VIPS_SHORT}
rm bin/libvips-cpp-42.dll
cp bin/*.dll lib/

# Create platform.json
printf "\"${PLATFORM}\"" >platform.json

# Add third-party notices
$CURL -O https://raw.githubusercontent.com/lovell/sharp-libvips/master/THIRD-PARTY-NOTICES.md

echo "Creating tarball"
tar czf /packaging/libvips-${VERSION_VIPS}-${PLATFORM}.tar.gz \
  include \
  lib/glib-2.0 \
  lib/libvips.lib \
  lib/libglib-2.0.lib \
  lib/libgobject-2.0.lib \
  lib/*.dll \
  *.json \
  THIRD-PARTY-NOTICES.md

# Recompress using AdvanceCOMP, ~5% smaller
advdef --recompress --shrink-insane /packaging/libvips-${VERSION_VIPS}-${PLATFORM}.tar.gz

# Recompress using Brotli, ~15% smaller
gunzip -c /packaging/libvips-${VERSION_VIPS}-${PLATFORM}.tar.gz | brotli -o /packaging/libvips-${VERSION_VIPS}-${PLATFORM}.tar.br

# Allow tarballs to be read outside container
chmod 644 /packaging/libvips-${VERSION_VIPS}-${PLATFORM}.tar.*

# Remove working directories
rm -rf lib include *.json THIRD-PARTY-NOTICES.md
