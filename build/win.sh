#!/bin/sh
set -e

VERSION_VIPS_MAJOR=$(echo $VERSION_VIPS | cut -d. -f1)
VERSION_VIPS_MINOR=$(echo $VERSION_VIPS | cut -d. -f2)

# Fetch and unzip
mkdir /vips
cd /vips
curl -LO https://github.com/lovell/build-win64/releases/download/v${VERSION_VIPS}/vips-dev-w64-web-${VERSION_VIPS}.zip
unzip vips-dev-w64-web-${VERSION_VIPS}.zip

# Clean and zip
cd /vips/vips-dev-${VERSION_VIPS_MAJOR}.${VERSION_VIPS_MINOR}
rm bin/libvips-cpp-42.dll
cp bin/*.dll lib/

# Create platform.json
printf "\"${PLATFORM}\"" >platform.json

# Create versions.json
curl -LO https://raw.githubusercontent.com/lovell/build-win64/v${VERSION_VIPS}/${VERSION_VIPS_MAJOR}.${VERSION_VIPS_MINOR}/vips.modules
version_of() {
  xmllint --xpath "string(/moduleset/autotools[@id='$1']/branch/@version | /moduleset/cmake[@id='$1']/branch/@version | /moduleset/meson[@id='$1']/branch/@version)" vips.modules
}
printf "{\n\
  \"cairo\": \"$(version_of cairo)\",\n\
  \"croco\": \"$(version_of libcroco)\",\n\
  \"exif\": \"$(version_of libexif)\",\n\
  \"expat\": \"$(version_of expat)\",\n\
  \"ffi\": \"$(version_of libffi)\",\n\
  \"fontconfig\": \"$(version_of fontconfig)\",\n\
  \"freetype\": \"$(version_of freetype)\",\n\
  \"fribidi\": \"$(version_of fribidi)\",\n\
  \"gdkpixbuf\": \"$(version_of gdk-pixbuf)\",\n\
  \"gettext\": \"$(version_of gettext)\",\n\
  \"gif\": \"$(version_of giflib)\",\n\
  \"glib\": \"$(version_of glib)\",\n\
  \"gsf\": \"$(version_of libgsf)\",\n\
  \"harfbuzz\": \"$(version_of harfbuzz)\",\n\
  \"jpeg\": \"$(version_of libjpeg-turbo)\",\n\
  \"lcms\": \"$(version_of lcms)\",\n\
  \"pango\": \"$(version_of pango)\",\n\
  \"pixman\": \"$(version_of pixman)\",\n\
  \"png\": \"$(version_of libpng)\",\n\
  \"svg\": \"$(version_of librsvg)\",\n\
  \"tiff\": \"$(version_of tiff)\",\n\
  \"vips\": \"${VERSION_VIPS}\",\n\
  \"webp\": \"$(version_of webp)\",\n\
  \"xml\": \"$(version_of libxml2)\",\n\
  \"zlib\": \"$(version_of zlib)\"\n\
}" >versions.json
rm vips.modules
cat versions.json

echo "Creating tarball"
tar czf /packaging/libvips-${VERSION_VIPS}-${PLATFORM}.tar.gz include lib/glib-2.0 lib/libvips.lib lib/libglib-2.0.lib lib/libgobject-2.0.lib lib/*.dll *.json
echo "Shrinking tarball"
advdef --recompress --shrink-insane /packaging/libvips-${VERSION_VIPS}-${PLATFORM}.tar.gz
