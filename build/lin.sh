#!/bin/sh
set -e

# Working directories
DEPS=/deps
TARGET=/target
mkdir ${DEPS}
mkdir ${TARGET}

# Common build paths and flags
export PKG_CONFIG_PATH="${PKG_CONFIG_PATH}:${TARGET}/lib/pkgconfig"
export PATH="${PATH}:${TARGET}/bin"
export CPPFLAGS="-I${TARGET}/include"
export LDFLAGS="-L${TARGET}/lib -Wl,-rpath='\$\$ORIGIN'"
export LD_LIBRARY_PATH="${TARGET}/lib"
export CFLAGS="${FLAGS}"
export CXXFLAGS="${FLAGS}"

# Dependency version numbers
VERSION_ZLIB=1.2.11
VERSION_FFI=3.3
VERSION_GLIB=2.63.2
VERSION_XML2=2.9.10
VERSION_GSF=1.14.46
VERSION_EXIF=0.6.21
VERSION_LCMS2=2.9
VERSION_JPEG=2.0.3
VERSION_PNG16=1.6.37
VERSION_WEBP=1.0.3
VERSION_TIFF=4.1.0
VERSION_ORC=0.4.31
VERSION_GETTEXT=0.20.1
VERSION_GDKPIXBUF=2.40.0
VERSION_FREETYPE=2.10.1
VERSION_EXPAT=2.2.9
VERSION_FONTCONFIG=2.13.92
VERSION_HARFBUZZ=2.6.4
VERSION_PIXMAN=0.38.4
VERSION_CAIRO=1.16.0
VERSION_FRIBIDI=1.0.8
VERSION_PANGO=1.44.7
VERSION_CROCO=0.6.13
VERSION_SVG=2.46.4
VERSION_GIF=5.1.4

# Remove patch version component
without_patch() {
  echo "$1" | sed "s/\.[0-9]*$//"
}

# Check for newer versions
ALL_AT_VERSION_LATEST=true
version_latest() {
  VERSION_LATEST=$(curl -s https://release-monitoring.org/api/project/$3 | jq -r '.versions[]' | grep -E -m1 '^[0-9]+(.[0-9]+)*$')
  if [ "$VERSION_LATEST" != "$2" ]; then
    ALL_AT_VERSION_LATEST=false
    echo "$1 version $2 has been superseded by $VERSION_LATEST"
  fi
}
version_latest "zlib" "$VERSION_ZLIB" "5303"
version_latest "ffi" "$VERSION_FFI" "1611"
version_latest "glib" "$VERSION_GLIB" "10024"
version_latest "xml2" "$VERSION_XML2" "1783"
version_latest "gsf" "$VERSION_GSF" "1980"
version_latest "exif" "$VERSION_EXIF" "1607"
version_latest "lcms2" "$VERSION_LCMS2" "9815"
version_latest "jpeg" "$VERSION_JPEG" "1648"
version_latest "png" "$VERSION_PNG16" "1705"
version_latest "webp" "$VERSION_WEBP" "1761"
version_latest "tiff" "$VERSION_TIFF" "13521"
version_latest "orc" "$VERSION_ORC" "2573"
version_latest "gettext" "$VERSION_GETTEXT" "898"
version_latest "gdkpixbuf" "$VERSION_GDKPIXBUF" "9533"
version_latest "freetype" "$VERSION_FREETYPE" "854"
version_latest "expat" "$VERSION_EXPAT" "770"
version_latest "fontconfig" "$VERSION_FONTCONFIG" "827"
version_latest "harfbuzz" "$VERSION_HARFBUZZ" "1299"
version_latest "pixman" "$VERSION_PIXMAN" "3648"
#version_latest "cairo" "$VERSION_CAIRO" "247" # latest version in release monitoring does not exist
version_latest "fribidi" "$VERSION_FRIBIDI" "857"
version_latest "pango" "$VERSION_PANGO" "11783"
version_latest "croco" "$VERSION_CROCO" "11787"
#version_latest "svg" "$VERSION_SVG" "5420" # v2.47.0+ requires rust>=1.36 but rustup does not support musl
#version_latest "gif" "$VERSION_GIF" "1158" # v5.1.5+ provides a Makefile only so will require custom cross-compilation setup
if [ "$ALL_AT_VERSION_LATEST" = "false" ]; then exit 1; fi

# Download and build dependencies from source

case ${PLATFORM} in *musl*)
  mkdir ${DEPS}/gettext
  curl -Ls https://ftp.gnu.org/pub/gnu/gettext/gettext-${VERSION_GETTEXT}.tar.xz | tar xJC ${DEPS}/gettext --strip-components=1
  cd ${DEPS}/gettext
  ./configure --host=${CHOST} --prefix=${TARGET} --enable-shared --disable-static --disable-dependency-tracking
  make install-strip
  rm ${TARGET}/include/gettext-po.h
  rm -rf ${TARGET}/lib/*gettext*
  export LDFLAGS="-L${TARGET}/lib -lintl -Wl,-rpath='\$ORIGIN'"
esac

mkdir ${DEPS}/zlib
curl -Ls https://zlib.net/zlib-${VERSION_ZLIB}.tar.xz | tar xJC ${DEPS}/zlib --strip-components=1
cd ${DEPS}/zlib
./configure --prefix=${TARGET} --uname=linux
make install
rm ${TARGET}/lib/libz.a

mkdir ${DEPS}/ffi
curl -Ls https://sourceware.org/pub/libffi/libffi-${VERSION_FFI}.tar.gz | tar xzC ${DEPS}/ffi --strip-components=1
cd ${DEPS}/ffi
sed -i 's/@toolexeclibdir@/$(libdir)/g' Makefile.in
./configure --host=${CHOST} --prefix=${TARGET} --enable-shared --disable-static --disable-dependency-tracking --disable-builddir
make install-strip

mkdir ${DEPS}/glib
curl -Lks https://download.gnome.org/sources/glib/$(without_patch $VERSION_GLIB)/glib-${VERSION_GLIB}.tar.xz | tar xJC ${DEPS}/glib --strip-components=1
cd ${DEPS}/glib
CFLAGS= CXXFLAGS= meson setup _build --buildtype=release --strip --libdir=lib --prefix=${TARGET} ${MESON} \
  -Dinternal_pcre=true -Dlibmount=false
ninja -C _build
ninja -C _build install

mkdir ${DEPS}/xml2
curl -Ls http://xmlsoft.org/sources/libxml2-${VERSION_XML2}.tar.gz | tar xzC ${DEPS}/xml2 --strip-components=1
cd ${DEPS}/xml2
./configure --host=${CHOST} --prefix=${TARGET} --enable-shared --disable-static --disable-dependency-tracking \
  --without-python --without-debug --without-docbook --without-ftp --without-html --without-legacy \
  --without-push --without-schematron --with-zlib=${TARGET}
make install-strip

mkdir ${DEPS}/gsf
curl -Lks https://download.gnome.org/sources/libgsf/$(without_patch $VERSION_GSF)/libgsf-${VERSION_GSF}.tar.xz | tar xJC ${DEPS}/gsf --strip-components=1
cd ${DEPS}/gsf
./configure --host=${CHOST} --prefix=${TARGET} --enable-shared --disable-static --disable-dependency-tracking \
  --without-bz2 --without-gdk-pixbuf
make install-strip

mkdir ${DEPS}/exif
curl -Ls https://sourceforge.mirrorservice.org/l/li/libexif/libexif/${VERSION_EXIF}/libexif-${VERSION_EXIF}.tar.bz2 | tar xjC ${DEPS}/exif --strip-components=1
cd ${DEPS}/exif
autoreconf -fiv
./configure --host=${CHOST} --prefix=${TARGET} --enable-shared --disable-static --disable-dependency-tracking
make install-strip

mkdir ${DEPS}/lcms2
curl -Ls https://sourceforge.mirrorservice.org/l/lc/lcms/lcms/${VERSION_LCMS2}/lcms2-${VERSION_LCMS2}.tar.gz | tar xzC ${DEPS}/lcms2 --strip-components=1
cd ${DEPS}/lcms2
./configure --host=${CHOST} --prefix=${TARGET} --enable-shared --disable-static --disable-dependency-tracking
make install-strip

mkdir ${DEPS}/jpeg
curl -Ls https://github.com/libjpeg-turbo/libjpeg-turbo/archive/${VERSION_JPEG}.tar.gz | tar xzC ${DEPS}/jpeg --strip-components=1
cd ${DEPS}/jpeg
cmake -G"Unix Makefiles" -DCMAKE_TOOLCHAIN_FILE=/root/Toolchain.cmake -DCMAKE_INSTALL_PREFIX=${TARGET} -DCMAKE_INSTALL_LIBDIR=${TARGET}/lib \
  -DENABLE_SHARED=TRUE -DENABLE_STATIC=FALSE -DWITH_JPEG8=1 -DWITH_TURBOJPEG=FALSE
make install/strip

mkdir ${DEPS}/png16
curl -Ls https://sourceforge.mirrorservice.org/l/li/libpng/libpng16/${VERSION_PNG16}/libpng-${VERSION_PNG16}.tar.xz | tar xJC ${DEPS}/png16 --strip-components=1
cd ${DEPS}/png16
./configure --host=${CHOST} --prefix=${TARGET} --enable-shared --disable-static --disable-dependency-tracking
make install-strip

mkdir ${DEPS}/webp
curl -Ls https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-${VERSION_WEBP}.tar.gz | tar xzC ${DEPS}/webp --strip-components=1
cd ${DEPS}/webp
./configure --host=${CHOST} --prefix=${TARGET} --enable-shared --disable-static --disable-dependency-tracking \
  --disable-neon --enable-libwebpmux
make install-strip

mkdir ${DEPS}/tiff
curl -Ls https://download.osgeo.org/libtiff/tiff-${VERSION_TIFF}.tar.gz | tar xzC ${DEPS}/tiff --strip-components=1
cd ${DEPS}/tiff
if [ -n "${CHOST}" ]; then autoreconf -fiv; fi
./configure --host=${CHOST} --prefix=${TARGET} --enable-shared --disable-static --disable-dependency-tracking --disable-mdi --disable-pixarlog --disable-cxx
make install-strip

mkdir ${DEPS}/orc
curl -Ls https://gstreamer.freedesktop.org/data/src/orc/orc-${VERSION_ORC}.tar.xz | tar xJC ${DEPS}/orc --strip-components=1
cd ${DEPS}/orc
CFLAGS= CXXFLAGS= meson setup _build --buildtype=release --strip --libdir=lib --prefix=${TARGET} ${MESON} \
  -Dorc-test=disabled -Dbenchmarks=disabled -Dexamples=disabled -Dgtk_doc=disabled -Dtests=disabled -Dtools=disabled
ninja -C _build
ninja -C _build install

mkdir ${DEPS}/gdkpixbuf
curl -Lks https://download.gnome.org/sources/gdk-pixbuf/$(without_patch $VERSION_GDKPIXBUF)/gdk-pixbuf-${VERSION_GDKPIXBUF}.tar.xz | tar xJC ${DEPS}/gdkpixbuf --strip-components=1
cd ${DEPS}/gdkpixbuf
CFLAGS= CXXFLAGS= meson setup _build --buildtype=release --strip --libdir=lib --prefix=${TARGET} ${MESON} \
  -Dtiff=false -Dx11=false -Dgir=false -Dinstalled_tests=false -Dgio_sniffing=false -Dman=false -Dbuiltin_loaders=png,jpeg
ninja -C _build
ninja -C _build install

mkdir ${DEPS}/freetype
curl -Ls https://download.savannah.gnu.org/releases/freetype/freetype-${VERSION_FREETYPE}.tar.xz | tar xJC ${DEPS}/freetype --strip-components=1
cd ${DEPS}/freetype
./configure --host=${CHOST} --prefix=${TARGET} --enable-shared --disable-static --disable-dependency-tracking \
  --without-bzip2
make install

mkdir ${DEPS}/expat
curl -Ls https://github.com/libexpat/libexpat/releases/download/R_2_2_9/expat-${VERSION_EXPAT}.tar.xz | tar xJC ${DEPS}/expat --strip-components=1
cd ${DEPS}/expat
./configure --host=${CHOST} --prefix=${TARGET} --enable-shared --disable-static \
  --disable-dependency-tracking --without-xmlwf --without-docbook --without-getrandom --without-sys-getrandom
make install

mkdir ${DEPS}/fontconfig
curl -Ls https://www.freedesktop.org/software/fontconfig/release/fontconfig-${VERSION_FONTCONFIG}.tar.xz | tar xJC ${DEPS}/fontconfig --strip-components=1
cd ${DEPS}/fontconfig
./configure --host=${CHOST} --prefix=${TARGET} --enable-shared --disable-static --disable-dependency-tracking \
  --with-expat-includes=${TARGET}/include --with-expat-lib=${TARGET}/lib --sysconfdir=/etc --disable-docs
make install-strip

mkdir ${DEPS}/harfbuzz
curl -Ls https://www.freedesktop.org/software/harfbuzz/release/harfbuzz-${VERSION_HARFBUZZ}.tar.xz | tar xJC ${DEPS}/harfbuzz --strip-components=1
cd ${DEPS}/harfbuzz
sed -i "s/error   \"-Wunused-local-typedefs\"/ignored \"-Wunused-local-typedefs\"/" src/hb.hh
./configure --host=${CHOST} --prefix=${TARGET} --enable-shared --disable-static --disable-dependency-tracking
make install-strip
rm ${TARGET}/lib/libharfbuzz-subset*

mkdir ${DEPS}/pixman
curl -Ls https://cairographics.org/releases/pixman-${VERSION_PIXMAN}.tar.gz | tar xzC ${DEPS}/pixman --strip-components=1
cd ${DEPS}/pixman
./configure --host=${CHOST} --prefix=${TARGET} --enable-shared --disable-static --disable-dependency-tracking \
  --disable-libpng --disable-arm-iwmmxt
make install-strip

mkdir ${DEPS}/cairo
curl -Ls https://cairographics.org/releases/cairo-${VERSION_CAIRO}.tar.xz | tar xJC ${DEPS}/cairo --strip-components=1
cd ${DEPS}/cairo
./configure --host=${CHOST} --prefix=${TARGET} --enable-shared --disable-static --disable-dependency-tracking \
  --disable-xlib --disable-xcb --disable-quartz --disable-win32 --disable-egl --disable-glx --disable-wgl \
  --disable-ps --disable-trace --disable-interpreter
make install-strip

mkdir ${DEPS}/fribidi
curl -Ls https://github.com/fribidi/fribidi/releases/download/v${VERSION_FRIBIDI}/fribidi-${VERSION_FRIBIDI}.tar.bz2 | tar xjC ${DEPS}/fribidi --strip-components=1
cd ${DEPS}/fribidi
autoreconf -fiv
./configure --host=${CHOST} --prefix=${TARGET} --enable-shared --disable-static --disable-dependency-tracking
make install-strip

mkdir ${DEPS}/pango
curl -Lks https://download.gnome.org/sources/pango/$(without_patch $VERSION_PANGO)/pango-${VERSION_PANGO}.tar.xz | tar xJC ${DEPS}/pango --strip-components=1
cd ${DEPS}/pango
CFLAGS= CXXFLAGS= meson setup _build --buildtype=release --strip --libdir=lib --prefix=${TARGET} ${MESON} \
  -Dgtk_doc=false -Dintrospection=false
ninja -C _build
ninja -C _build install

mkdir ${DEPS}/croco
curl -Lks https://download.gnome.org/sources/libcroco/$(without_patch $VERSION_CROCO)/libcroco-${VERSION_CROCO}.tar.xz | tar xJC ${DEPS}/croco --strip-components=1
cd ${DEPS}/croco
./configure --host=${CHOST} --prefix=${TARGET} --enable-shared --disable-static --disable-dependency-tracking
make install-strip

mkdir ${DEPS}/svg
curl -Lks https://download.gnome.org/sources/librsvg/$(without_patch $VERSION_SVG)/librsvg-${VERSION_SVG}.tar.xz | tar xJC ${DEPS}/svg --strip-components=1
cd ${DEPS}/svg
# Optimise Rust code for binary size
sed -i "s/debug = true/debug = false\ncodegen-units = 1\nincremental = false\npanic = \"abort\"\nopt-level = \"s\"/" Cargo.toml
./configure --host=${CHOST} --prefix=${TARGET} --enable-shared --disable-static --disable-dependency-tracking \
  --disable-introspection --disable-tools --disable-pixbuf-loader
make install-strip
# Clear executable bit from librsvg shared library for WSL support
execstack -c ${TARGET}/lib/librsvg-2.so || true

mkdir ${DEPS}/gif
curl -Ls https://sourceforge.mirrorservice.org/g/gi/giflib/giflib-${VERSION_GIF}.tar.gz | tar xzC ${DEPS}/gif --strip-components=1
cd ${DEPS}/gif
./configure --host=${CHOST} --prefix=${TARGET} --enable-shared --disable-static --disable-dependency-tracking
make install-strip

mkdir ${DEPS}/vips
curl -Ls https://github.com/libvips/libvips/releases/download/v${VERSION_VIPS}/vips-${VERSION_VIPS}.tar.gz | tar xzC ${DEPS}/vips --strip-components=1
cd ${DEPS}/vips
./configure --host=${CHOST} --prefix=${TARGET} --enable-shared --disable-static --disable-dependency-tracking \
  --disable-debug --disable-introspection --without-python --without-fftw \
  --without-magick --without-pangoft2 --without-ppm --without-analyze --without-radiance \
  --with-zip-includes=${TARGET}/include --with-zip-libraries=${TARGET}/lib \
  --with-jpeg-includes=${TARGET}/include --with-jpeg-libraries=${TARGET}/lib
make install-strip

# Remove the old C++ bindings
cd ${TARGET}/include
rm -rf vips/vipsc++.h vips/vipscpp.h
cd ${TARGET}/lib
rm -rf pkgconfig .libs *.la libvipsCC*

# Create JSON file of version numbers
cd ${TARGET}
printf "{\n\
  \"cairo\": \"${VERSION_CAIRO}\",\n\
  \"croco\": \"${VERSION_CROCO}\",\n\
  \"exif\": \"${VERSION_EXIF}\",\n\
  \"expat\": \"${VERSION_EXPAT}\",\n\
  \"ffi\": \"${VERSION_FFI}\",\n\
  \"fontconfig\": \"${VERSION_FONTCONFIG}\",\n\
  \"freetype\": \"${VERSION_FREETYPE}\",\n\
  \"fribidi\": \"${VERSION_FRIBIDI}\",\n\
  \"gdkpixbuf\": \"${VERSION_GDKPIXBUF}\",\n\
  \"gettext\": \"${VERSION_GETTEXT}\",\n\
  \"gif\": \"${VERSION_GIF}\",\n\
  \"glib\": \"${VERSION_GLIB}\",\n\
  \"gsf\": \"${VERSION_GSF}\",\n\
  \"harfbuzz\": \"${VERSION_HARFBUZZ}\",\n\
  \"jpeg\": \"${VERSION_JPEG}\",\n\
  \"lcms\": \"${VERSION_LCMS2}\",\n\
  \"orc\": \"${VERSION_ORC}\",\n\
  \"pango\": \"${VERSION_PANGO}\",\n\
  \"pixman\": \"${VERSION_PIXMAN}\",\n\
  \"png\": \"${VERSION_PNG16}\",\n\
  \"svg\": \"${VERSION_SVG}\",\n\
  \"tiff\": \"${VERSION_TIFF}\",\n\
  \"vips\": \"${VERSION_VIPS}\",\n\
  \"webp\": \"${VERSION_WEBP}\",\n\
  \"xml\": \"${VERSION_XML2}\",\n\
  \"zlib\": \"${VERSION_ZLIB}\"\n\
}" >versions.json

printf "\"${PLATFORM}\"" >platform.json

# Create .tar.gz
tar czf /packaging/libvips-${VERSION_VIPS}-${PLATFORM}.tar.gz include lib *.json
advdef --recompress --shrink-insane /packaging/libvips-${VERSION_VIPS}-${PLATFORM}.tar.gz
