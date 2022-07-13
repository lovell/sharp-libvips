#!/usr/bin/env bash
set -e

# Environment / working directories
case ${PLATFORM} in
  linux*)
    LINUX=true
    DEPS=/deps
    TARGET=/target
    PACKAGE=/packaging
    ROOT=/root
    VIPS_CPP_DEP=libvips-cpp.so.42
    ;;
  darwin*)
    DARWIN=true
    DEPS=$PWD/deps
    TARGET=$PWD/target
    PACKAGE=$PWD
    ROOT=$PWD/$PLATFORM
    VIPS_CPP_DEP=libvips-cpp.42.dylib
    ;;
esac

mkdir ${DEPS}
mkdir ${TARGET}

# Default optimisation level is for binary size (-Os)
# Overriden to performance (-O3) for select dependencies that benefit
export FLAGS+=" -Os -fPIC"

# Force "new" C++11 ABI compliance
# Remove async exception unwind/backtrace tables
# Allow linker to remove unused sections
if [ "$LINUX" = true ]; then
  export FLAGS+=" -D_GLIBCXX_USE_CXX11_ABI=1 -fno-asynchronous-unwind-tables -ffunction-sections -fdata-sections"
fi

# Common build paths and flags
export PKG_CONFIG_LIBDIR="${TARGET}/lib/pkgconfig"
export PATH="${PATH}:${TARGET}/bin"
export LD_LIBRARY_PATH="${TARGET}/lib"
export CFLAGS="${FLAGS}"
export CXXFLAGS="${FLAGS}"
export OBJCFLAGS="${FLAGS}"
export OBJCXXFLAGS="${FLAGS}"
export CPPFLAGS="-I${TARGET}/include"
export LDFLAGS="-L${TARGET}/lib"

# On Linux, we need to create a relocatable library
# Note: this is handled for macOS using the `install_name_tool` (see below)
if [ "$LINUX" = true ]; then
  export LDFLAGS+=" -Wl,--gc-sections -Wl,-rpath=\$ORIGIN/"
fi

if [ "$DARWIN" = true ]; then
  # Local rust installation
  export CARGO_HOME="${DEPS}/cargo"
  export RUSTUP_HOME="${DEPS}/rustup"
  mkdir -p $CARGO_HOME
  mkdir -p $RUSTUP_HOME
  export PATH="${CARGO_HOME}/bin:${PATH}"
  if [ "$PLATFORM" == "darwin-arm64v8" ]; then
    export DARWIN_ARM=true
  fi
fi

# Run as many parallel jobs as there are available CPU cores
if [ "$LINUX" = true ]; then
  export MAKEFLAGS="-j$(nproc)"
elif [ "$DARWIN" = true ]; then
  export MAKEFLAGS="-j$(sysctl -n hw.logicalcpu)"
fi

# Optimise Rust code for binary size
export CARGO_PROFILE_RELEASE_DEBUG=false
export CARGO_PROFILE_RELEASE_CODEGEN_UNITS=1
export CARGO_PROFILE_RELEASE_INCREMENTAL=false
export CARGO_PROFILE_RELEASE_LTO=true
export CARGO_PROFILE_RELEASE_OPT_LEVEL=z
export CARGO_PROFILE_RELEASE_PANIC=abort

# We don't want to use any native libraries, so unset PKG_CONFIG_PATH
unset PKG_CONFIG_PATH

# Common options for curl
CURL="curl --silent --location --retry 3 --retry-max-time 30"

# Dependency version numbers
VERSION_ZLIB_NG=2.0.6
VERSION_FFI=3.4.2
VERSION_GLIB=2.73.2
VERSION_XML2=2.9.14
VERSION_GSF=1.14.49
VERSION_EXIF=0.6.24
VERSION_LCMS2=2.13.1
VERSION_MOZJPEG=4.0.3
VERSION_PNG16=1.6.37
VERSION_SPNG=0.7.2
VERSION_IMAGEQUANT=2.4.1
VERSION_WEBP=1.2.2
VERSION_TIFF=4.4.0
VERSION_ORC=0.4.32
VERSION_PROXY_LIBINTL=0.4
VERSION_GDKPIXBUF=2.42.8
VERSION_FREETYPE=2.12.1
VERSION_EXPAT=2.4.8
VERSION_FONTCONFIG=2.14.0
VERSION_HARFBUZZ=4.4.1
VERSION_PIXMAN=0.40.0
VERSION_CAIRO=1.17.6
VERSION_FRIBIDI=1.0.12
VERSION_PANGO=1.50.8
VERSION_SVG=2.54.4
VERSION_AOM=3.4.0
VERSION_HEIF=1.12.0
VERSION_CGIF=0.3.0

# Remove patch version component
without_patch() {
  echo "${1%.[[:digit:]]*}"
}

# Check for newer versions
# Skip by setting the VERSION_LATEST_REQUIRED environment variable to "false"
ALL_AT_VERSION_LATEST=true
version_latest() {
  if [ "$VERSION_LATEST_REQUIRED" == "false" ]; then
    echo "Skipping latest version check for $1"
    return
  fi
  VERSION_SELECTOR="stable_versions"
  if [[ "$4" == *"unstable"* ]]; then
    VERSION_SELECTOR="versions"
  fi
  if [[ "$3" == *"/"* ]]; then
    VERSION_LATEST=$(git ls-remote --tags --refs https://github.com/$3.git | sort -t'/' -k3 -V | awk -F'/' 'END{print $3}' | tr -d 'vV')
  else
    VERSION_LATEST=$($CURL "https://release-monitoring.org/api/v2/versions/?project_id=$3" | jq -j ".$VERSION_SELECTOR[0]" | tr '_' '.')
  fi
  if [ "$VERSION_LATEST" != "$2" ]; then
    ALL_AT_VERSION_LATEST=false
    echo "$1 version $2 has been superseded by $VERSION_LATEST"
  fi
}
version_latest "zlib-ng" "$VERSION_ZLIB_NG" "115592"
version_latest "ffi" "$VERSION_FFI" "1611"
version_latest "glib" "$VERSION_GLIB" "10024" "unstable"
version_latest "xml2" "$VERSION_XML2" "1783"
version_latest "gsf" "$VERSION_GSF" "1980"
version_latest "exif" "$VERSION_EXIF" "1607"
version_latest "lcms2" "$VERSION_LCMS2" "9815"
version_latest "mozjpeg" "$VERSION_MOZJPEG" "mozilla/mozjpeg"
version_latest "png" "$VERSION_PNG16" "1705"
version_latest "spng" "$VERSION_SPNG" "24289"
version_latest "webp" "$VERSION_WEBP" "1761"
version_latest "tiff" "$VERSION_TIFF" "1738"
version_latest "orc" "$VERSION_ORC" "2573"
version_latest "proxy-libintl" "$VERSION_PROXY_LIBINTL" "frida/proxy-libintl"
version_latest "gdkpixbuf" "$VERSION_GDKPIXBUF" "9533"
version_latest "freetype" "$VERSION_FREETYPE" "854"
version_latest "expat" "$VERSION_EXPAT" "770"
version_latest "fontconfig" "$VERSION_FONTCONFIG" "827"
version_latest "harfbuzz" "$VERSION_HARFBUZZ" "1299"
version_latest "pixman" "$VERSION_PIXMAN" "3648"
version_latest "cairo" "$VERSION_CAIRO" "247"
version_latest "fribidi" "$VERSION_FRIBIDI" "857"
version_latest "pango" "$VERSION_PANGO" "11783"
version_latest "svg" "$VERSION_SVG" "5420"
version_latest "aom" "$VERSION_AOM" "17628"
version_latest "heif" "$VERSION_HEIF" "64439"
version_latest "cgif" "$VERSION_CGIF" "dloebl/cgif"
if [ "$ALL_AT_VERSION_LATEST" = "false" ]; then exit 1; fi

# Download and build dependencies from source

if [ "$DARWIN" = true ]; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
    | sh -s -- -y --no-modify-path --profile minimal
  if [ "$DARWIN_ARM" = true ]; then
    ${CARGO_HOME}/bin/rustup target add aarch64-apple-darwin
  fi
fi

if [ "${PLATFORM%-*}" == "linuxmusl" ] || [ "$DARWIN" = true ]; then
  # musl and macOS requires the standalone intl support library of gettext, since it's not provided by libc (like GNU).
  # We use a stub version of gettext instead, since we don't need any of the i18n features.
  mkdir ${DEPS}/proxy-libintl
  $CURL https://github.com/frida/proxy-libintl/archive/${VERSION_PROXY_LIBINTL}.tar.gz | tar xzC ${DEPS}/proxy-libintl --strip-components=1
  cd ${DEPS}/proxy-libintl
  meson setup _build --default-library=static --buildtype=release --strip --prefix=${TARGET} ${MESON}
  ninja -C _build
  ninja -C _build install
fi

mkdir ${DEPS}/zlib-ng
$CURL https://github.com/zlib-ng/zlib-ng/archive/${VERSION_ZLIB_NG}.tar.gz | tar xzC ${DEPS}/zlib-ng --strip-components=1
cd ${DEPS}/zlib-ng
CFLAGS="${CFLAGS} -O3" cmake -G"Unix Makefiles" \
  -DCMAKE_TOOLCHAIN_FILE=${ROOT}/Toolchain.cmake -DCMAKE_INSTALL_PREFIX=${TARGET} -DBUILD_SHARED_LIBS=FALSE -DZLIB_COMPAT=TRUE
make install/strip

mkdir ${DEPS}/ffi
$CURL https://github.com/libffi/libffi/releases/download/v${VERSION_FFI}/libffi-${VERSION_FFI}.tar.gz | tar xzC ${DEPS}/ffi --strip-components=1
cd ${DEPS}/ffi
./configure --host=${CHOST} --prefix=${TARGET} --enable-static --disable-shared --disable-dependency-tracking \
  --disable-builddir --disable-multi-os-directory --disable-raw-api --disable-structs
make install-strip

mkdir ${DEPS}/glib
$CURL https://download.gnome.org/sources/glib/$(without_patch $VERSION_GLIB)/glib-${VERSION_GLIB}.tar.xz | tar xJC ${DEPS}/glib --strip-components=1
cd ${DEPS}/glib
if [ "$DARWIN" = true ]; then
  $CURL https://gist.github.com/kleisauke/f6dcbf02a9aa43fd582272c3d815e7a8/raw/75b1e06250bdb0df067be4a5db54df960f35c46d/glib-proxy-libintl.patch | patch -p1
fi
if [ "${PLATFORM%-*}" == "linuxmusl" ]; then
  # https://gitlab.gnome.org/GNOME/glib/-/issues/2692
  $CURL https://gitlab.gnome.org/GNOME/glib/-/commit/871e5708679b96e63ee574f5c74e0e746f4be9a4.patch | patch -p1
fi
$CURL https://gist.github.com/kleisauke/284d685efa00908da99ea6afbaaf39ae/raw/af997aa5b6bdb27484c6d9f16d9255d79c86aa77/glib-without-gregex.patch | patch -p1
meson setup _build --default-library=static --buildtype=release --strip --prefix=${TARGET} ${MESON} \
  --force-fallback-for=gvdb -Dnls=disabled -Dtests=false -Dinstalled_tests=false -Dlibmount=disabled -Dlibelf=disabled ${DARWIN:+-Dbsymbolic_functions=false}
ninja -C _build
ninja -C _build install

mkdir ${DEPS}/xml2
$CURL https://download.gnome.org/sources/libxml2/$(without_patch $VERSION_XML2)/libxml2-${VERSION_XML2}.tar.xz | tar xJC ${DEPS}/xml2 --strip-components=1
cd ${DEPS}/xml2
./configure --host=${CHOST} --prefix=${TARGET} --enable-static --disable-shared --disable-dependency-tracking \
  --with-minimum --with-reader --with-writer --with-valid --with-http --with-tree --with-zlib --without-python --without-lzma
make install-strip

mkdir ${DEPS}/gsf
$CURL https://download.gnome.org/sources/libgsf/$(without_patch $VERSION_GSF)/libgsf-${VERSION_GSF}.tar.xz | tar xJC ${DEPS}/gsf --strip-components=1
cd ${DEPS}/gsf
# Skip unused subdirs
sed -i'.bak' "s/ doc tools tests thumbnailer python//" Makefile.in
./configure --host=${CHOST} --prefix=${TARGET} --enable-static --disable-shared --disable-dependency-tracking \
  --without-bz2 --without-gdk-pixbuf --disable-nls --without-libiconv-prefix --without-libintl-prefix
make install-strip

mkdir ${DEPS}/exif
$CURL https://github.com/libexif/libexif/releases/download/v${VERSION_EXIF}/libexif-${VERSION_EXIF}.tar.bz2 | tar xjC ${DEPS}/exif --strip-components=1
cd ${DEPS}/exif
./configure --host=${CHOST} --prefix=${TARGET} --enable-static --disable-shared --disable-dependency-tracking \
  --disable-nls --without-libiconv-prefix --without-libintl-prefix \
  CPPFLAGS="${CPPFLAGS} -DNO_VERBOSE_TAG_DATA"
make install-strip

mkdir ${DEPS}/lcms2
$CURL https://github.com/mm2/Little-CMS/releases/download/lcms${VERSION_LCMS2}/lcms2-${VERSION_LCMS2}.tar.gz | tar xzC ${DEPS}/lcms2 --strip-components=1
cd ${DEPS}/lcms2
CFLAGS="${CFLAGS} -O3" ./configure --host=${CHOST} --prefix=${TARGET} --enable-static --disable-shared --disable-dependency-tracking
make install-strip

mkdir ${DEPS}/aom
$CURL https://storage.googleapis.com/aom-releases/libaom-${VERSION_AOM}.tar.gz | tar xzC ${DEPS}/aom --strip-components=1
cd ${DEPS}/aom
mkdir aom_build
cd aom_build
AOM_AS_FLAGS="${FLAGS}" cmake -G"Unix Makefiles" \
  -DCMAKE_TOOLCHAIN_FILE=${ROOT}/Toolchain.cmake -DCMAKE_INSTALL_PREFIX=${TARGET} -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_BUILD_TYPE=MinSizeRel \
  -DBUILD_SHARED_LIBS=FALSE -DENABLE_DOCS=0 -DENABLE_TESTS=0 -DENABLE_TESTDATA=0 -DENABLE_TOOLS=0 -DENABLE_EXAMPLES=0 \
  -DCONFIG_PIC=1 -DENABLE_NASM=1 ${WITHOUT_NEON:+-DENABLE_NEON=0} ${DARWIN_ARM:+-DCONFIG_RUNTIME_CPU_DETECT=0} \
  -DCONFIG_AV1_HIGHBITDEPTH=0 -DCONFIG_WEBM_IO=0 \
  ..
make install/strip

mkdir ${DEPS}/heif
$CURL https://github.com/strukturag/libheif/releases/download/v${VERSION_HEIF}/libheif-${VERSION_HEIF}.tar.gz | tar xzC ${DEPS}/heif --strip-components=1
cd ${DEPS}/heif
# [PATCH] aom encoder: improve performance by ~2x using new 'all intra'
$CURL https://github.com/strukturag/libheif/commit/de0c159a60c2c50931321f06e36a3b6640c5c807.patch | patch -p1
# [PATCH] aom: expose decoder error messages
$CURL https://github.com/strukturag/libheif/commit/7e1c1888023f6dd68cf33e537e7eb8e4d5e17588.patch | patch -p1
# [PATCH] Detect and prevent negative overflow of clap box dimensions
$CURL https://github.com/strukturag/libheif/commit/e625a702ec7d46ce042922547d76045294af71d6.patch | git apply -
# [PATCH] Avoid lroundf
$CURL https://github.com/strukturag/libheif/commit/499a0a31d79936042c7abeef2513bb0b56b81489.patch | patch -p1
# [PATCH] Add API to sanitize enums relating to color profiles
$CURL https://github.com/kleisauke/libheif/commit/0d44224914946a00d293c08bbaf4553acc985802.patch | patch -p1
autoreconf -fiv
CFLAGS="${CFLAGS} -O3" CXXFLAGS="${CXXFLAGS} -O3" ./configure \
  --host=${CHOST} --prefix=${TARGET} --enable-static --disable-shared --disable-dependency-tracking \
  --disable-gdk-pixbuf --disable-go --disable-examples --disable-libde265 --disable-x265
make install-strip

mkdir ${DEPS}/jpeg
$CURL https://github.com/mozilla/mozjpeg/archive/v${VERSION_MOZJPEG}.tar.gz | tar xzC ${DEPS}/jpeg --strip-components=1
cd ${DEPS}/jpeg
cmake -G"Unix Makefiles" -DCMAKE_BUILD_TYPE=MinSizeRel \
  -DCMAKE_TOOLCHAIN_FILE=${ROOT}/Toolchain.cmake -DCMAKE_INSTALL_PREFIX=${TARGET} -DCMAKE_INSTALL_LIBDIR=${TARGET}/lib \
  -DENABLE_STATIC=TRUE -DENABLE_SHARED=FALSE -DWITH_JPEG8=1 -DWITH_TURBOJPEG=FALSE -DPNG_SUPPORTED=FALSE
make install/strip

mkdir ${DEPS}/png16
$CURL https://downloads.sourceforge.net/project/libpng/libpng16/${VERSION_PNG16}/libpng-${VERSION_PNG16}.tar.xz | tar xJC ${DEPS}/png16 --strip-components=1
cd ${DEPS}/png16
./configure --host=${CHOST} --prefix=${TARGET} --enable-static --disable-shared --disable-dependency-tracking
make install-strip

mkdir ${DEPS}/spng
$CURL https://github.com/randy408/libspng/archive/v${VERSION_SPNG}.tar.gz | tar xzC ${DEPS}/spng --strip-components=1
cd ${DEPS}/spng
CFLAGS="${CFLAGS} -O3" meson setup _build --default-library=static --buildtype=release --strip --prefix=${TARGET} ${MESON} \
  -Dstatic_zlib=true
ninja -C _build
ninja -C _build install

mkdir ${DEPS}/imagequant
$CURL https://github.com/lovell/libimagequant/archive/v${VERSION_IMAGEQUANT}.tar.gz | tar xzC ${DEPS}/imagequant --strip-components=1
cd ${DEPS}/imagequant
CFLAGS="${CFLAGS} -O3" meson setup _build --default-library=static --buildtype=release --strip --prefix=${TARGET} ${MESON}
ninja -C _build
ninja -C _build install

mkdir ${DEPS}/webp
$CURL https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-${VERSION_WEBP}.tar.gz | tar xzC ${DEPS}/webp --strip-components=1
cd ${DEPS}/webp
./configure --host=${CHOST} --prefix=${TARGET} --enable-static --disable-shared --disable-dependency-tracking \
  --enable-libwebpmux --enable-libwebpdemux ${WITHOUT_NEON:+--disable-neon}
make install-strip

mkdir ${DEPS}/tiff
$CURL https://download.osgeo.org/libtiff/tiff-${VERSION_TIFF}.tar.gz | tar xzC ${DEPS}/tiff --strip-components=1
cd ${DEPS}/tiff
# Propagate -pthread into CFLAGS to ensure WebP support
CFLAGS="${CFLAGS} -pthread" ./configure --host=${CHOST} --prefix=${TARGET} --enable-static --disable-shared --disable-dependency-tracking \
  --disable-mdi --disable-pixarlog --disable-old-jpeg --disable-cxx --disable-lzma --disable-zstd
make install-strip

mkdir ${DEPS}/orc
$CURL https://gstreamer.freedesktop.org/data/src/orc/orc-${VERSION_ORC}.tar.xz | tar xJC ${DEPS}/orc --strip-components=1
cd ${DEPS}/orc
meson setup _build --default-library=static --buildtype=release --strip --prefix=${TARGET} ${MESON} \
  -Dorc-test=disabled -Dbenchmarks=disabled -Dexamples=disabled -Dgtk_doc=disabled -Dtests=disabled -Dtools=disabled
ninja -C _build
ninja -C _build install

mkdir ${DEPS}/gdkpixbuf
$CURL https://download.gnome.org/sources/gdk-pixbuf/$(without_patch $VERSION_GDKPIXBUF)/gdk-pixbuf-${VERSION_GDKPIXBUF}.tar.xz | tar xJC ${DEPS}/gdkpixbuf --strip-components=1
cd ${DEPS}/gdkpixbuf
# Disable tests and thumbnailer
sed -i'.bak' "/subdir('tests')/{N;d;}" meson.build
sed -i'.bak' "/post-install/{N;N;N;N;d;}" meson.build
# Disable the built-in loaders for BMP, GIF, ICO, PNM, XPM, XBM, TGA, ICNS and QTIF
sed -i'.bak' "/'bmp':/{N;N;N;N;N;N;N;N;N;N;N;N;N;N;N;d;}" gdk-pixbuf/meson.build
sed -i'.bak' "/'pnm':/{N;N;N;N;N;N;N;N;N;N;N;N;N;N;N;N;N;N;N;N;N;N;N;N;N;N;N;d;}" gdk-pixbuf/meson.build
# Skip executables
sed -i'.bak' "/gdk-pixbuf-csource/{N;N;d;}" gdk-pixbuf/meson.build
sed -i'.bak' "/loaders_cache = custom/{N;N;N;N;N;N;N;N;N;c\\
  loaders_cache = []\\
  loaders_dep = declare_dependency()
}" gdk-pixbuf/meson.build
meson setup _build --default-library=static --buildtype=release --strip --prefix=${TARGET} ${MESON} \
  -Dtiff=disabled -Dintrospection=disabled -Dinstalled_tests=false -Dgio_sniffing=false -Dman=false -Dbuiltin_loaders=png,jpeg
ninja -C _build
ninja -C _build install
# Include libjpeg and libpng as a dependency of gdk-pixbuf, see: https://gitlab.gnome.org/GNOME/gdk-pixbuf/merge_requests/50
sed -i'.bak' "s/^\(Requires:.*\)/\1 libjpeg, libpng16/" ${TARGET}/lib/pkgconfig/gdk-pixbuf-2.0.pc

mkdir ${DEPS}/freetype
$CURL https://download.savannah.gnu.org/releases/freetype/freetype-${VERSION_FREETYPE}.tar.xz | tar xJC ${DEPS}/freetype --strip-components=1
cd ${DEPS}/freetype
meson setup _build --default-library=static --buildtype=release --strip --prefix=${TARGET} ${MESON} \
  -Dzlib=enabled -Dpng=disabled -Dharfbuzz=disabled -Dbrotli=disabled -Dbzip2=disabled
ninja -C _build
ninja -C _build install

mkdir ${DEPS}/expat
$CURL https://github.com/libexpat/libexpat/releases/download/R_${VERSION_EXPAT//./_}/expat-${VERSION_EXPAT}.tar.xz | tar xJC ${DEPS}/expat --strip-components=1
cd ${DEPS}/expat
./configure --host=${CHOST} --prefix=${TARGET} --enable-static --disable-shared \
  --disable-dependency-tracking --without-xmlwf --without-docbook --without-getrandom --without-sys-getrandom \
  --without-libbsd --without-examples --without-tests
make install-strip

mkdir ${DEPS}/fontconfig
$CURL https://www.freedesktop.org/software/fontconfig/release/fontconfig-${VERSION_FONTCONFIG}.tar.xz | tar xJC ${DEPS}/fontconfig --strip-components=1
cd ${DEPS}/fontconfig
meson setup _build --default-library=static --buildtype=release --strip --prefix=${TARGET} ${MESON} \
  -Dcache-build=disabled -Ddoc=disabled -Dnls=disabled -Dtests=disabled -Dtools=disabled \
  ${LINUX:+--sysconfdir=/etc} ${DARWIN:+--sysconfdir=/usr/local/etc}
ninja -C _build
ninja -C _build install

mkdir ${DEPS}/harfbuzz
$CURL https://github.com/harfbuzz/harfbuzz/archive/${VERSION_HARFBUZZ}.tar.gz | tar xzC ${DEPS}/harfbuzz --strip-components=1
cd ${DEPS}/harfbuzz
# https://github.com/harfbuzz/harfbuzz/pull/3707
$CURL https://github.com/kleisauke/harfbuzz/commit/94bfd2ff7a4b4e7949f0ac0834b2bf38a1feea12.patch | patch -p1
$CURL https://github.com/kleisauke/harfbuzz/commit/43f5ee43753cf4df5dc7811fc8a464f97a4551c2.patch | patch -p1
$CURL https://github.com/kleisauke/harfbuzz/commit/23aa63c955202fc7e8caac59c0c656edddc84dba.patch | patch -p1
# Disable utils
sed -i'.bak' "/subdir('util')/d" meson.build
meson setup _build --default-library=static --buildtype=release --strip --prefix=${TARGET} ${MESON} \
  -Dgobject=disabled -Dicu=disabled -Dtests=disabled -Dintrospection=disabled -Ddocs=disabled -Dbenchmark=disabled ${DARWIN:+-Dcoretext=enabled}
ninja -C _build
ninja -C _build install

mkdir ${DEPS}/pixman
$CURL https://cairographics.org/releases/pixman-${VERSION_PIXMAN}.tar.gz | tar xzC ${DEPS}/pixman --strip-components=1
cd ${DEPS}/pixman
# Disable tests and demos
sed -i'.bak' "/subdir('test')/{N;d;}" meson.build
meson setup _build --default-library=static --buildtype=release --strip --prefix=${TARGET} ${MESON} \
  -Dlibpng=disabled -Diwmmxt=disabled -Dgtk=disabled -Dopenmp=disabled
ninja -C _build
ninja -C _build install

mkdir ${DEPS}/cairo
$CURL https://gitlab.freedesktop.org/cairo/cairo/-/archive/${VERSION_CAIRO}/cairo-${VERSION_CAIRO}.tar.bz2 | tar xjC ${DEPS}/cairo --strip-components=1
cd ${DEPS}/cairo
meson setup _build --default-library=static --buildtype=release --strip --prefix=${TARGET} ${MESON} \
  ${LINUX:+-Dquartz=disabled} ${DARWIN:+-Dquartz=enabled} -Dxcb=disabled -Dxlib=disabled -Dzlib=disabled \
  -Dtests=disabled -Dspectre=disabled -Dsymbol-lookup=disabled
ninja -C _build
ninja -C _build install

mkdir ${DEPS}/fribidi
$CURL https://github.com/fribidi/fribidi/releases/download/v${VERSION_FRIBIDI}/fribidi-${VERSION_FRIBIDI}.tar.xz | tar xJC ${DEPS}/fribidi --strip-components=1
cd ${DEPS}/fribidi
# Disable tests
sed -i'.bak' "/subdir('test')/d" meson.build
meson setup _build --default-library=static --buildtype=release --strip --prefix=${TARGET} ${MESON} \
  -Ddocs=false
ninja -C _build
ninja -C _build install

mkdir ${DEPS}/pango
$CURL https://download.gnome.org/sources/pango/$(without_patch $VERSION_PANGO)/pango-${VERSION_PANGO}.tar.xz | tar xJC ${DEPS}/pango --strip-components=1
cd ${DEPS}/pango
# Disable utils, examples, tests and tools
sed -i'.bak' "/subdir('utils')/{N;N;N;d;}" meson.build
meson setup _build --default-library=static --buildtype=release --strip --prefix=${TARGET} ${MESON} \
  -Dgtk_doc=false -Dintrospection=disabled -Dfontconfig=enabled
ninja -C _build
ninja -C _build install

mkdir ${DEPS}/svg
$CURL https://download.gnome.org/sources/librsvg/$(without_patch $VERSION_SVG)/librsvg-${VERSION_SVG}.tar.xz | tar xJC ${DEPS}/svg --strip-components=1
cd ${DEPS}/svg
sed -i'.bak' "s/^\(Requires:.*\)/\1 cairo-gobject pangocairo/" librsvg.pc.in
# LTO optimization does not work for staticlib+rlib compilation
sed -i'.bak' "s/, \"rlib\"//" Cargo.toml
# Skip executables
sed -i'.bak' "/SCRIPTS = /d" Makefile.in
# Use target/CARGO_BUILD_TARGET/release instead of target/release when set
if [[ $CARGO_BUILD_TARGET ]]; then
  sed -i'.bak' "s/@RUST_TARGET_SUBDIR@/$CARGO_BUILD_TARGET\/@RUST_TARGET_SUBDIR@/" Makefile.in
fi
# Remove the --static flag from the PKG_CONFIG env since Rust does not
# support that. Build with PKG_CONFIG_ALL_STATIC=1 instead.
PKG_CONFIG=${PKG_CONFIG/ --static/} ./configure --host=${CHOST} --prefix=${TARGET} --enable-static --disable-shared --disable-dependency-tracking \
  --disable-introspection --disable-tools --disable-pixbuf-loader --disable-nls --without-libiconv-prefix --without-libintl-prefix \
  ${DARWIN:+--disable-Bsymbolic}
PKG_CONFIG_ALL_STATIC=1 make install-strip

mkdir ${DEPS}/cgif
$CURL https://github.com/dloebl/cgif/archive/V${VERSION_CGIF}.tar.gz | tar xzC ${DEPS}/cgif --strip-components=1
cd ${DEPS}/cgif
CFLAGS="${CFLAGS} -O3" meson setup _build --default-library=static --buildtype=release --strip --prefix=${TARGET} ${MESON} \
  -Dtests=false
ninja -C _build
ninja -C _build install

mkdir ${DEPS}/vips
# TODO: Use the tarball for the next release https://github.com/libvips/libvips/issues/2876
#$CURL https://github.com/libvips/libvips/releases/download/v${VERSION_VIPS}/vips-${VERSION_VIPS}.tar.gz | tar xzC ${DEPS}/vips --strip-components=1
$CURL https://github.com/libvips/libvips/archive/refs/tags/v${VERSION_VIPS}.tar.gz | tar xzC ${DEPS}/vips --strip-components=1
cd ${DEPS}/vips
# Link libvips.so.42 statically into libvips-cpp.so.42
sed -i'.bak' "s/library('vips'/static_&/" libvips/meson.build
sed -i'.bak' "/version: library_version/{N;d;}" libvips/meson.build
if [ "$LINUX" = true ]; then
  # Ensure symbols from external libs (except for libglib-2.0.a and libgobject-2.0.a) are not exposed
  EXCLUDE_LIBS=$(find ${TARGET}/lib -maxdepth 1 -name '*.a' ! -name 'libglib-2.0.a' ! -name 'libgobject-2.0.a' -printf "-Wl,--exclude-libs=%f ")
  EXCLUDE_LIBS=${EXCLUDE_LIBS%?}
  # Localize the g_param_spec_types symbol to avoid collisions with shared libraries
  # See: https://github.com/lovell/sharp/issues/2535#issuecomment-766400693
  printf "{local:g_param_spec_types;};" > vips.map
elif [ "$DARWIN" = true ]; then
  # https://github.com/pybind/pybind11/issues/595
  export STRIP="strip -x"
fi
# Disable building man pages, gettext po files, tools, and (fuzz-)tests
sed -i'.bak' "/subdir('man')/{N;N;N;N;d;}" meson.build
CFLAGS="${CFLAGS} -O3" CXXFLAGS="${CXXFLAGS} -O3" meson setup _build --default-library=shared --buildtype=release --strip --prefix=${TARGET} ${MESON} \
  -Ddeprecated=false -Dintrospection=false -Dmodules=disabled -Dcfitsio=disabled -Dfftw=disabled -Djpeg-xl=disabled \
  -Dmagick=disabled -Dmatio=disabled -Dnifti=disabled -Dopenexr=disabled -Dopenjpeg=disabled -Dopenslide=disabled \
  -Dpdfium=disabled -Dpoppler=disabled -Dquantizr=disabled -Dppm=false -Danalyze=false -Dradiance=false \
  ${LINUX:+-Dcpp_link_args="$LDFLAGS -Wl,-Bsymbolic-functions -Wl,--version-script=$DEPS/vips/vips.map $EXCLUDE_LIBS"}
ninja -C _build
ninja -C _build install

# Cleanup
rm -rf ${TARGET}/lib/{pkgconfig,.libs,*.la,cmake}

mkdir ${TARGET}/lib-filtered
mv ${TARGET}/lib/glib-2.0 ${TARGET}/lib-filtered

# Pack only the relevant libraries
# Note: we can't use ldd on Linux, since that can only be executed on the target machine
# Note 2: we modify all dylib dependencies to use relative paths on macOS
function copydeps {
  local base=$1
  local dest_dir=$2

  cp -L $base $dest_dir/$base
  chmod 644 $dest_dir/$base

  if [ "$LINUX" = true ]; then
    local dependencies=$(readelf -d $base | grep NEEDED | awk '{ print $5 }' | tr -d '[]')
  elif [ "$DARWIN" = true ]; then
    local dependencies=$(otool -LX $base | awk '{print $1}' | grep $TARGET)

    install_name_tool -id @rpath/$base $dest_dir/$base
  fi

  for dep in $dependencies; do
    base_dep=$(basename $dep)

    [ ! -f "$PWD/$base_dep" ] && echo "$base_dep does not exist in $PWD" && continue
    echo "$base depends on $base_dep"

    if [ ! -f "$dest_dir/$base_dep" ]; then
      if [ "$DARWIN" = true ]; then
        install_name_tool -change $dep @rpath/$base_dep $dest_dir/$base
      fi

      # Call this function (recursive) on each dependency of this library
      copydeps $base_dep $dest_dir
    fi
  done;
}

cd ${TARGET}/lib
copydeps ${VIPS_CPP_DEP} ${TARGET}/lib-filtered

# Create JSON file of version numbers
cd ${TARGET}
printf "{\n\
  \"aom\": \"${VERSION_AOM}\",\n\
  \"cairo\": \"${VERSION_CAIRO}\",\n\
  \"cgif\": \"${VERSION_CGIF}\",\n\
  \"exif\": \"${VERSION_EXIF}\",\n\
  \"expat\": \"${VERSION_EXPAT}\",\n\
  \"ffi\": \"${VERSION_FFI}\",\n\
  \"fontconfig\": \"${VERSION_FONTCONFIG}\",\n\
  \"freetype\": \"${VERSION_FREETYPE}\",\n\
  \"fribidi\": \"${VERSION_FRIBIDI}\",\n\
  \"gdkpixbuf\": \"${VERSION_GDKPIXBUF}\",\n\
  \"glib\": \"${VERSION_GLIB}\",\n\
  \"gsf\": \"${VERSION_GSF}\",\n\
  \"harfbuzz\": \"${VERSION_HARFBUZZ}\",\n\
  \"heif\": \"${VERSION_HEIF}\",\n\
  \"imagequant\": \"${VERSION_IMAGEQUANT}\",\n\
  \"lcms\": \"${VERSION_LCMS2}\",\n\
  \"mozjpeg\": \"${VERSION_MOZJPEG}\",\n\
  \"orc\": \"${VERSION_ORC}\",\n\
  \"pango\": \"${VERSION_PANGO}\",\n\
  \"pixman\": \"${VERSION_PIXMAN}\",\n\
  \"png\": \"${VERSION_PNG16}\",\n\
  \"proxy-libintl\": \"${VERSION_PROXY_LIBINTL}\",\n\
  \"svg\": \"${VERSION_SVG}\",\n\
  \"spng\": \"${VERSION_SPNG}\",\n\
  \"tiff\": \"${VERSION_TIFF}\",\n\
  \"vips\": \"${VERSION_VIPS}\",\n\
  \"webp\": \"${VERSION_WEBP}\",\n\
  \"xml\": \"${VERSION_XML2}\",\n\
  \"zlib-ng\": \"${VERSION_ZLIB_NG}\"\n\
}" >versions.json

printf "\"${PLATFORM}\"" >platform.json

# Add third-party notices
$CURL -O https://raw.githubusercontent.com/lovell/sharp-libvips/main/THIRD-PARTY-NOTICES.md

# Create the tarball
ls -al lib
rm -rf lib
mv lib-filtered lib
tar chzf ${PACKAGE}/libvips-${VERSION_VIPS}-${PLATFORM}.tar.gz \
  include \
  lib \
  *.json \
  THIRD-PARTY-NOTICES.md

# Recompress using AdvanceCOMP, ~5% smaller
advdef --recompress --shrink-insane ${PACKAGE}/libvips-${VERSION_VIPS}-${PLATFORM}.tar.gz

# Recompress using Brotli, ~15% smaller
gunzip -c ${PACKAGE}/libvips-${VERSION_VIPS}-${PLATFORM}.tar.gz | brotli -o ${PACKAGE}/libvips-${VERSION_VIPS}-${PLATFORM}.tar.br

# Allow tarballs to be read outside container
chmod 644 ${PACKAGE}/libvips-${VERSION_VIPS}-${PLATFORM}.tar.*
