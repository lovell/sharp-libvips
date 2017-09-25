#!/bin/sh
set -e

VERSION_VIPS_MAJOR=$(echo $VERSION_VIPS | cut -d. -f1)
VERSION_VIPS_MINOR=$(echo $VERSION_VIPS | cut -d. -f2)

# Fetch and unzip
mkdir /vips
cd /vips
curl -L -O https://github.com/lovell/build-win64/releases/download/v${VERSION_VIPS}/vips-dev-w64-web-${VERSION_VIPS}.zip
unzip vips-dev-w64-web-${VERSION_VIPS}.zip

# Clean and zip
cd /vips/vips-dev-${VERSION_VIPS_MAJOR}.${VERSION_VIPS_MINOR}
rm bin/libvipsCC-42.dll bin/libvips-cpp-42.dll bin/libgsf-win32-1-114.dll
cp bin/*.dll lib/
cp -r lib64/* lib/

echo "\"${PLATFORM}\"" >platform.json

echo "Creating tarball"
tar czf /packaging/libvips-${VERSION_VIPS}-${PLATFORM}.tar.gz include lib/glib-2.0 lib/libvips.lib lib/libglib-2.0.lib lib/libgobject-2.0.lib lib/*.dll *.json
echo "Shrinking tarball"
advdef --recompress --shrink-insane /packaging/libvips-${VERSION_VIPS}-${PLATFORM}.tar.gz
