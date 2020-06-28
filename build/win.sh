#!/usr/bin/env bash
set -e

VERSION_VIPS_SHORT=${VERSION_VIPS%.[[:digit:]]*}

# Fetch and unzip
mkdir /vips
cd /vips
BITS=${PLATFORM: -2}
curl -LOs https://github.com/libvips/build-win64-mxe/releases/download/v${VERSION_VIPS}/vips-dev-w${BITS}-web-${VERSION_VIPS}-static.zip
unzip vips-dev-w${BITS}-web-${VERSION_VIPS}-static.zip

# Clean and zip
cd /vips/vips-dev-${VERSION_VIPS_SHORT}
rm bin/libvips-cpp-42.dll
cp bin/*.dll lib/

# Create platform.json
printf "\"${PLATFORM}\"" >platform.json

# Add third-party notices
curl -Os https://raw.githubusercontent.com/lovell/sharp-libvips/master/THIRD-PARTY-NOTICES.md

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
