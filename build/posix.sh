#!/usr/bin/env bash
set -e

# Dependency version numbers
if [ -f /packaging/versions.properties ]; then
  source /packaging/versions.properties
fi

# Remove patch version component
without_patch() {
  echo "${1%.[[:digit:]]*}"
}
# Remove prerelease suffix
without_prerelease() {
  echo "${1%-[[:alnum:]]*}"
}

# Environment / working directories
case ${PLATFORM} in
  linux*)
    LINUX=true
    DEPS=/deps
    TARGET=/target
    PACKAGE=/packaging
    ROOT=/root
    VIPS_CPP_DEP=libvips-cpp.so.$(without_prerelease $VERSION_VIPS)
    ;;
  darwin*)
    DARWIN=true
    DEPS=$PWD/deps
    TARGET=$PWD/target
    PACKAGE=$PWD
    ROOT=$PWD/platforms/$PLATFORM
    VIPS_CPP_DEP=libvips-cpp.$(without_prerelease $VERSION_VIPS).dylib
    ;;
esac

mkdir ${DEPS}
mkdir ${TARGET}

# Default optimisation level is for binary size (-Os)
# Overriden to performance (-O3) for select dependencies that benefit
export FLAGS+=" -O3 -fPIC"

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
  # Let macOS linker remove unused code
  export LDFLAGS+=" -Wl,-dead_strip"
  # Local rust installation
  export CARGO_HOME="${DEPS}/cargo"
  export RUSTUP_HOME="${DEPS}/rustup"
  mkdir -p $CARGO_HOME
  mkdir -p $RUSTUP_HOME
  export PATH="${CARGO_HOME}/bin:${PATH}"
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

# Ensure Cargo build path prefixes are removed from the resulting binaries
# https://reproducible-builds.org/docs/build-path/
export RUSTFLAGS+=" --remap-path-prefix=$CARGO_HOME/registry/="

# We don't want to use any native libraries, so unset PKG_CONFIG_PATH
unset PKG_CONFIG_PATH

# Common options for curl
CURL="curl --silent --location --retry 3 --retry-max-time 30"

# Download and build dependencies from source

if [ "$DARWIN" = true ]; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
    | sh -s -- -y --no-modify-path --profile minimal --default-toolchain nightly
  export RUSTFLAGS+=" -Zlocation-detail=none -Zfmt-debug=none"
  CFLAGS= cargo install cargo-c --locked
fi

if [ "${PLATFORM%-*}" == "linuxmusl" ] || [ "$DARWIN" = true ]; then
  # musl and macOS requires the standalone intl support library of gettext, since it's not provided by libc (like GNU).
  # We use a stub version of gettext instead, since we don't need any of the i18n features.
  mkdir ${DEPS}/proxy-libintl
  $CURL https://github.com/frida/proxy-libintl/archive/${VERSION_PROXY_LIBINTL}.tar.gz | tar xzC ${DEPS}/proxy-libintl --strip-components=1
  cd ${DEPS}/proxy-libintl
  meson setup _build --default-library=static --buildtype=release --strip --prefix=${TARGET} ${MESON}
  meson install -C _build --tag devel
fi

###### NASM #### LIBAOM need nasm > 2.14
mkdir ${DEPS}/nasm
$CURL http://www.nasm.us/pub/nasm/releasebuilds/2.16.01/nasm-2.16.01.tar.xz | tar xJC ${DEPS}/nasm --strip-components=1
cd ${DEPS}/nasm
./configure --host=${CHOST} --prefix=${TARGET}
make && make install
#######

mkdir ${DEPS}/zlib
$CURL https://www.zlib.net/fossils/zlib-${VERSION_ZLIB}.tar.gz | tar xzC ${DEPS}/zlib --strip-components=1
cd ${DEPS}/zlib
CFLAGS="${CFLAGS} -O3" ./configure --prefix=${TARGET} ${LINUX:+--uname=linux} ${DARWIN:+--uname=darwin} --static
make install

mkdir ${DEPS}/ffi
$CURL https://github.com/libffi/libffi/releases/download/v${VERSION_FFI}/libffi-${VERSION_FFI}.tar.gz | tar xzC ${DEPS}/ffi --strip-components=1
cd ${DEPS}/ffi
./configure --host=${CHOST} --prefix=${TARGET} --enable-static --disable-shared --disable-dependency-tracking \
  --disable-builddir --disable-multi-os-directory --disable-raw-api --disable-structs
make install-strip

mkdir ${DEPS}/glib
$CURL https://download.gnome.org/sources/glib/$(without_patch $VERSION_GLIB)/glib-${VERSION_GLIB}.tar.xz | tar xJC ${DEPS}/glib --strip-components=1
cd ${DEPS}/glib
$CURL https://gist.github.com/kleisauke/284d685efa00908da99ea6afbaaf39ae/raw/36e32c79e7962c5ea96cbb3f9c629e9145253e30/glib-without-gregex.patch | patch -p1
meson setup _build --default-library=static --buildtype=release --strip --prefix=${TARGET} ${MESON} \
  --force-fallback-for=gvdb -Dnls=disabled -Dtests=false -Dinstalled_tests=false -Dlibmount=disabled -Dlibelf=disabled \
  -Dglib_assert=false -Dglib_checks=false ${DARWIN:+-Dbsymbolic_functions=false}
# bin-devel is needed for glib-compile-resources, as required by gdk-pixbuf
meson install -C _build --tag bin-devel,devel

mkdir ${DEPS}/xml2
$CURL https://download.gnome.org/sources/libxml2/$(without_patch $VERSION_XML2)/libxml2-${VERSION_XML2}.tar.xz | tar xJC ${DEPS}/xml2 --strip-components=1
cd ${DEPS}/xml2
meson setup _build --default-library=static --buildtype=release --strip --prefix=${TARGET} ${MESON} \
  -Dminimum=true
meson install -C _build --tag devel

##### imagemagick libxml/parser.h not found fix
# cd /target/include; ln -s libxml2/libxml . 
pkg-config --modversion libxml-2.0
pkg-config --libs libxml-2.0 
pkg-config --cflags libxml-2.0
# exit 0

mkdir ${DEPS}/exif
$CURL https://github.com/libexif/libexif/releases/download/v${VERSION_EXIF}/libexif-${VERSION_EXIF}.tar.bz2 | tar xjC ${DEPS}/exif --strip-components=1
cd ${DEPS}/exif
$CURL https://github.com/lovell/libexif/commit/db84aefa1deb103604c5860dd6486b1dd3af676b.patch | patch -p1
./configure --host=${CHOST} --prefix=${TARGET} --enable-static --disable-shared --disable-dependency-tracking \
  --disable-nls --without-libiconv-prefix --without-libintl-prefix \
  CPPFLAGS="${CPPFLAGS} -DNO_VERBOSE_TAG_DATA"
make install-strip

mkdir ${DEPS}/lcms2
$CURL https://github.com/mm2/Little-CMS/releases/download/lcms${VERSION_LCMS2}/lcms2-${VERSION_LCMS2}.tar.gz | tar xzC ${DEPS}/lcms2 --strip-components=1
cd ${DEPS}/lcms2
CFLAGS="${CFLAGS} -O3" meson setup _build --default-library=static --buildtype=release --strip --prefix=${TARGET} ${MESON}
meson install -C _build --tag devel

mkdir ${DEPS}/png16
$CURL https://downloads.sourceforge.net/project/libpng/libpng16/${VERSION_PNG16}/libpng-${VERSION_PNG16}.tar.xz | tar xJC ${DEPS}/png16 --strip-components=1
cd ${DEPS}/png16
./configure --host=${CHOST} --prefix=${TARGET} --enable-static --disable-shared --disable-dependency-tracking \
  --disable-tools --without-binconfigs --disable-unversioned-libpng-config
make install-strip dist_man_MANS=

mkdir ${DEPS}/jpeg
$CURL https://github.com/mozilla/mozjpeg/archive/v${VERSION_MOZJPEG}.tar.gz | tar xzC ${DEPS}/jpeg --strip-components=1
cd ${DEPS}/jpeg
cmake -G"Unix Makefiles" \
  -DCMAKE_TOOLCHAIN_FILE=${ROOT}/Toolchain.cmake -DCMAKE_INSTALL_PREFIX=${TARGET} -DCMAKE_INSTALL_LIBDIR:PATH=lib -DCMAKE_BUILD_TYPE=MinSizeRel \
  -DENABLE_STATIC=TRUE -DENABLE_SHARED=FALSE -DWITH_JPEG8=1 -DWITH_TURBOJPEG=FALSE -DPNG_SUPPORTED=FALSE
make install/strip

mkdir ${DEPS}/spng
$CURL https://github.com/randy408/libspng/archive/v${VERSION_SPNG}.tar.gz | tar xzC ${DEPS}/spng --strip-components=1
cd ${DEPS}/spng
CFLAGS="${CFLAGS} -O3 -DSPNG_SSE=4" meson setup _build --default-library=static --buildtype=release --strip --prefix=${TARGET} ${MESON} \
  -Dstatic_zlib=true -Dbuild_examples=false
meson install -C _build --tag devel

# for default version 2.4.1
mkdir ${DEPS}/imagequant
$CURL https://github.com/lovell/libimagequant/archive/v${VERSION_IMAGEQUANT}.tar.gz | tar xzC ${DEPS}/imagequant --strip-components=1
cd ${DEPS}/imagequant
CFLAGS="${CFLAGS} -O3" meson setup _build --default-library=static --buildtype=release --strip --prefix=${TARGET} ${MESON}
meson install -C _build --tag devel

###### custom package - Pngquant
mkdir ${DEPS}/pngquant
curl -Ls http://pngquant.org/pngquant-${VERSION_PNGQUANT}-src.tar.gz | tar xzC ${DEPS}/pngquant --strip-components=1
# curl -Ls https://github.com/kornelski/pngquant/archive/refs/tags/${VERSION_PNGQUANT}.tar.gz | tar xzC ${DEPS}/pngquant --strip-components=1
cd ${DEPS}/pngquant
./configure --host=${CHOST} --prefix=${TARGET}
make -j2 
make install

mkdir ${DEPS}/aom
$CURL https://storage.googleapis.com/aom-releases/libaom-${VERSION_AOM}.tar.gz | tar xzC ${DEPS}/aom --strip-components=1
cd ${DEPS}/aom
mkdir aom_build
cd aom_build
#### =============================== CAREFUL ===============================
#### Do not add `-DCONFIG_AV1_HIGHBITDEPTH=0 -DCONFIG_WEBM_IO=0` to allow processing of high depth heif files
AOM_AS_FLAGS="${FLAGS}" cmake -G"Unix Makefiles" \
  -DCMAKE_TOOLCHAIN_FILE=${ROOT}/Toolchain.cmake -DCMAKE_INSTALL_PREFIX=${TARGET} -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_BUILD_TYPE=MinSizeRel \
  -DBUILD_SHARED_LIBS=FALSE -DENABLE_DOCS=0 -DENABLE_TESTS=0 -DENABLE_TESTDATA=0 -DENABLE_TOOLS=0 -DENABLE_EXAMPLES=0 \
  -DCONFIG_PIC=1 -DENABLE_NASM=1 -DCONFIG_AV1_HIGHBITDEPTH=1 -DCONFIG_WEBM_IO=1 \
  ..
make install

####### Custom lib - libde265
mkdir ${DEPS}/libde265
curl -Ls https://api.github.com/repos/strukturag/libde265/tarball/c7c724bfc873a7bebe1855b7a34c1e83337c1ff3 | tar xzC ${DEPS}/libde265 --strip-components=1
cd ${DEPS}/libde265
sh autogen.sh
./configure --host=${CHOST} --prefix=${TARGET} --disable-shared --enable-static --disable-dependency-tracking --disable-sherlock265
make install-strip
############################################################

mkdir ${DEPS}/heif
$CURL https://github.com/strukturag/libheif/releases/download/v${VERSION_HEIF}/libheif-${VERSION_HEIF}.tar.gz | tar xzC ${DEPS}/heif --strip-components=1
cd ${DEPS}/heif
# Downgrade minimum required CMake version to 3.12 - https://github.com/strukturag/libheif/issues/975
sed -i'.bak' "/^cmake_minimum_required/s/3.16.3/3.12/" CMakeLists.txt
CFLAGS="${CFLAGS} -O3" CXXFLAGS="${CXXFLAGS} -O3" cmake -G"Unix Makefiles" \
  -DCMAKE_TOOLCHAIN_FILE=${ROOT}/Toolchain.cmake -DCMAKE_INSTALL_PREFIX=${TARGET} -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=FALSE -DENABLE_PLUGIN_LOADING=0 -DWITH_EXAMPLES=1 -DWITH_LIBDE265=1 -DWITH_X265=0
make install

ls -l /target/bin
# /target/bin/heif-info -d /packaging/tests/libsharp/_80MP_10MB.avif | grep bit
# /target/bin/heif-dec --list-decoders
# /target/bin/heif-dec  /packaging/tests/libsharp/testavif.avif /packaging/tests/libsharp/testavif.jpg 
# echo one
# /target/bin/heif-dec  /packaging/tests/libsharp/_80MP_10MB.avif /packaging/tests/libsharp/_80MP_10MB.jpg 

###### custom package - ghostscript
mkdir ${DEPS}/ghostscript
$CURL https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/gs10040/ghostscript-${VERSION_GHOSTSCRIPT}.tar.xz | tar xJC ${DEPS}/ghostscript --strip-components=1
cd ${DEPS}/ghostscript
./configure --host=${CHOST} --prefix=${TARGET}
make so
make install

##### opencv build #### 
echo "VERSION_OPENCV: $VERSION_OPENCV"
export OPENCV4_LATEST=${VERSION_OPENCV}

rm -rf ${DEPS}/opencv
mkdir -p ${DEPS}/opencv ${TARGET}/lib
cd ${DEPS}/opencv/
wget https://github.com/opencv/opencv/archive/$VERSION_OPENCV.zip
unzip $VERSION_OPENCV.zip
rm -f $VERSION_OPENCV.zip
wget https://github.com/opencv/opencv_contrib/archive/$VERSION_OPENCV.zip
unzip $VERSION_OPENCV.zip
rm -f $VERSION_OPENCV.zip

cd opencv-$VERSION_OPENCV
mkdir -p build && cd build/

cmake -G"Unix Makefiles" -D BUILD_LIST=core,imgproc,imgcodecs,objdetect,highgui,features2d,calib3d,videoio \
    -D CMAKE_BUILD_TYPE=Release \
    -D CMAKE_TOOLCHAIN_FILE=${ROOT}/Toolchain.cmake \
    -D CMAKE_INSTALL_PREFIX=${TARGET} \
    -D OPENCV_EXTRA_MODULES_PATH=../../opencv_contrib-${VERSION_OPENCV}/modules \
    -D BUILD_SHARED_LIBS=ON \
	  -D WITH_TBB=OFF \
    -D WITH_V4L=OFF \
    -D WITH_QT=OFF \
	  -D WITH_EIGEN=ON \
	  -D BUILD_DOCS=OFF \
    -D BUILD_TESTS=OFF \
    -D BUILD_PERF_TESTS=OFF \
    -D BUILD_EXAMPLES=OFF \
	  -D WITH_CUDA=OFF \
    -D WITH_NVCUVID=OFF \
    -D WITH_IPP=OFF \
    -D WITH_OPENCL=OFF \
    -D WITH_OPENEXR=OFF \
    -D WITH_IPP_IW=OFF \
    -D WITH_ITT=OFF \
    -D WITH_JASPER=OFF \
    -D WITH_TIFF=OFF \
    -D BUILD_opencv_python2=OFF \
    -D PYTHON3_EXECUTABLE=/usr/bin/python3.9 \
    -D PYTHON3_LIBRARY=/usr/lib/python3.9 \
    -D PYTHON3_INCLUDE_DIR=/usr/include/python3.9 \
    -D OPENCV_GENERATE_PKGCONFIG=ON ..
make
make install

cp -r ${PACKAGE}/tools/exiftool ${TARGET}/bin/
ls -ltr ${TARGET}/bin/
ls -ltr ${TARGET}/lib/

mkdir ${DEPS}/webp
$CURL https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-${VERSION_WEBP}.tar.gz | tar xzC ${DEPS}/webp --strip-components=1
cd ${DEPS}/webp
./configure --host=${CHOST} --prefix=${TARGET} --enable-static --disable-shared --disable-dependency-tracking \
  --enable-libwebpmux --enable-libwebpdemux ${WITHOUT_NEON:+--disable-neon}
make install

mkdir ${DEPS}/tiff
$CURL https://download.osgeo.org/libtiff/tiff-${VERSION_TIFF}.tar.gz | tar xzC ${DEPS}/tiff --strip-components=1
cd ${DEPS}/tiff
# Propagate -pthread into CFLAGS to ensure WebP support
CFLAGS="${CFLAGS} -pthread" ./configure --host=${CHOST} --prefix=${TARGET} --enable-static --disable-shared --disable-dependency-tracking \
  --disable-tools --disable-tests --disable-contrib --disable-docs --disable-mdi --disable-pixarlog --disable-old-jpeg --disable-cxx --disable-lzma --disable-zstd
make install-strip noinst_PROGRAMS= dist_doc_DATA=

if [ -z "$WITHOUT_HIGHWAY" ]; then
  mkdir ${DEPS}/hwy
  $CURL https://github.com/google/highway/archive/${VERSION_HWY}.tar.gz | tar xzC ${DEPS}/hwy --strip-components=1
  cd ${DEPS}/hwy
  CFLAGS="${CFLAGS} -O3" CXXFLAGS="${CXXFLAGS} -O3" cmake -G"Unix Makefiles" \
    -DCMAKE_TOOLCHAIN_FILE=${ROOT}/Toolchain.cmake -DCMAKE_INSTALL_PREFIX=${TARGET} -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=FALSE -DBUILD_TESTING=0 -DHWY_ENABLE_CONTRIB=0 -DHWY_ENABLE_EXAMPLES=0 -DHWY_ENABLE_TESTS=0
  make install/strip
fi

build_freetype() {
  rm -rf ${DEPS}/freetype
  mkdir ${DEPS}/freetype
  $CURL https://github.com/freetype/freetype/archive/VER-${VERSION_FREETYPE//./-}.tar.gz | tar xzC ${DEPS}/freetype --strip-components=1
  cd ${DEPS}/freetype
  meson setup _build --default-library=static --buildtype=release --strip --prefix=${TARGET} ${MESON} \
    -Dzlib=enabled -Dpng=enabled -Dbrotli=disabled -Dbzip2=disabled "$@"
  meson install -C _build --tag devel
}
build_freetype -Dharfbuzz=disabled

mkdir ${DEPS}/expat
$CURL https://github.com/libexpat/libexpat/releases/download/R_${VERSION_EXPAT//./_}/expat-${VERSION_EXPAT}.tar.xz | tar xJC ${DEPS}/expat --strip-components=1
cd ${DEPS}/expat
./configure --host=${CHOST} --prefix=${TARGET} --enable-static --disable-shared \
  --disable-dependency-tracking --without-xmlwf --without-docbook --without-getrandom --without-sys-getrandom \
  --without-libbsd --without-examples --without-tests
make install-strip

mkdir ${DEPS}/archive
$CURL https://github.com/libarchive/libarchive/releases/download/v${VERSION_ARCHIVE}/libarchive-${VERSION_ARCHIVE}.tar.xz | tar xJC ${DEPS}/archive --strip-components=1
cd ${DEPS}/archive
./configure --host=${CHOST} --prefix=${TARGET} --enable-static --disable-shared --disable-dependency-tracking \
  --disable-bsdtar --disable-bsdcat --disable-bsdcpio --disable-bsdunzip --disable-posix-regex-lib --disable-xattr --disable-acl \
  --without-bz2lib --without-libb2 --without-iconv --without-lz4 --without-zstd --without-lzma \
  --without-lzo2 --without-cng --without-openssl --without-xml2 --without-expat
make install-strip libarchive_man_MANS=

mkdir ${DEPS}/fontconfig
$CURL https://www.freedesktop.org/software/fontconfig/release/fontconfig-${VERSION_FONTCONFIG}.tar.xz | tar xJC ${DEPS}/fontconfig --strip-components=1
cd ${DEPS}/fontconfig
meson setup _build --default-library=static --buildtype=release --strip --prefix=${TARGET} ${MESON} \
  -Dcache-build=disabled -Ddoc=disabled -Dnls=disabled -Dtests=disabled -Dtools=disabled
meson install -C _build --tag devel

mkdir ${DEPS}/harfbuzz
$CURL https://github.com/harfbuzz/harfbuzz/archive/${VERSION_HARFBUZZ}.tar.gz | tar xzC ${DEPS}/harfbuzz --strip-components=1
cd ${DEPS}/harfbuzz
# Disable utils
sed -i'.bak' "/subdir('util')/d" meson.build
meson setup _build --default-library=static --buildtype=release --strip --prefix=${TARGET} ${MESON} \
  -Dgobject=disabled -Dicu=disabled -Dtests=disabled -Dintrospection=disabled -Ddocs=disabled -Dbenchmark=disabled ${DARWIN:+-Dcoretext=enabled}
meson install -C _build --tag devel
# pkg-config provided by Amazon Linux 2 doesn't support circular `Requires` dependencies.
# https://bugs.freedesktop.org/show_bug.cgi?id=7331
# https://gitlab.freedesktop.org/pkg-config/pkg-config/-/commit/6d6dd43e75e2bc82cfe6544f8631b1bef6e1cf45
# TODO(kleisauke): Remove when Amazon Linux 2 reaches EOL.
sed -i'.bak' "/^Requires:/s/ freetype2.*,//" ${TARGET}/lib/pkgconfig/harfbuzz.pc
sed -i'.bak' "/^Libs:/s/$/ -lfreetype/" ${TARGET}/lib/pkgconfig/harfbuzz.pc
build_freetype -Dharfbuzz=enabled

mkdir ${DEPS}/pixman
$CURL https://cairographics.org/releases/pixman-${VERSION_PIXMAN}.tar.gz | tar xzC ${DEPS}/pixman --strip-components=1
cd ${DEPS}/pixman
# Disable tests and demos
meson setup _build --default-library=static --buildtype=release --strip --prefix=${TARGET} ${MESON} \
  -Dlibpng=disabled -Diwmmxt=disabled -Dgtk=disabled -Dopenmp=disabled -Dtests=disabled \
  ${DARWIN_ARM:+-Da64-neon=disabled}
meson install -C _build --tag devel

mkdir ${DEPS}/cairo
$CURL https://gitlab.freedesktop.org/cairo/cairo/-/archive/${VERSION_CAIRO}/cairo-${VERSION_CAIRO}.tar.bz2 | tar xjC ${DEPS}/cairo --strip-components=1
cd ${DEPS}/cairo
meson setup _build --default-library=static --buildtype=release --strip --prefix=${TARGET} ${MESON} \
  ${LINUX:+-Dquartz=disabled} ${DARWIN:+-Dquartz=enabled} -Dtee=disabled -Dxcb=disabled -Dxlib=disabled -Dzlib=disabled \
  -Dtests=disabled -Dspectre=disabled -Dsymbol-lookup=disabled
meson install -C _build --tag devel

mkdir ${DEPS}/fribidi
$CURL https://github.com/fribidi/fribidi/releases/download/v${VERSION_FRIBIDI}/fribidi-${VERSION_FRIBIDI}.tar.xz | tar xJC ${DEPS}/fribidi --strip-components=1
cd ${DEPS}/fribidi
meson setup _build --default-library=static --buildtype=release --strip --prefix=${TARGET} ${MESON} \
  -Ddocs=false -Dbin=false -Dtests=false
meson install -C _build --tag devel

mkdir ${DEPS}/pango
$CURL https://download.gnome.org/sources/pango/$(without_patch $VERSION_PANGO)/pango-${VERSION_PANGO}.tar.xz | tar xJC ${DEPS}/pango --strip-components=1
cd ${DEPS}/pango
# Disable utils and tools
sed -i'.bak' "/subdir('utils')/{N;d;}" meson.build
meson setup _build --default-library=static --buildtype=release --strip --prefix=${TARGET} ${MESON} \
  -Ddocumentation=false -Dbuild-testsuite=false -Dbuild-examples=false -Dintrospection=disabled -Dfontconfig=enabled
meson install -C _build --tag devel

mkdir ${DEPS}/rsvg
$CURL https://download.gnome.org/sources/librsvg/$(without_patch $VERSION_RSVG)/librsvg-${VERSION_RSVG}.tar.xz | tar xJC ${DEPS}/rsvg --strip-components=1
cd ${DEPS}/rsvg
# Disallow GIF and WebP embedded in SVG images
sed -i'.bak' "/image = /s/, \"gif\", \"webp\"//" rsvg/Cargo.toml
# We build Cairo with `-Dzlib=disabled`, which implicitly disables the PDF/PostScript surface backends
sed -i'.bak' "/cairo-rs = /s/, \"pdf\", \"ps\"//" {librsvg-c,rsvg}/Cargo.toml
# Skip build of rsvg-convert
sed -i'.bak' "/subdir('rsvg_convert')/d" meson.build
# https://github.com/etemesi254/zune-image/pull/187
# https://github.com/bevyengine/bevy/issues/14117#issuecomment-2236518551
# https://doc.rust-lang.org/cargo/reference/overriding-dependencies.html#the-patch-section
cat >> Cargo.toml <<EOL
[patch.crates-io]
zune-jpeg = { git = "https://github.com/ironpeak/zune-image.git", rev = "eebb01b" }
EOL
# Regenerate the lockfile after making the above changes
cargo generate-lockfile
# Remove the --static flag from the PKG_CONFIG env since Rust does not
# parse that correctly.
PKG_CONFIG=${PKG_CONFIG/ --static/} meson setup _build --default-library=static --buildtype=release --strip --prefix=${TARGET} ${MESON} \
  -Dintrospection=disabled -Dpixbuf{,-loader}=disabled -Ddocs=disabled -Dvala=disabled -Dtests=false \
  ${RUST_TARGET:+-Dtriplet=$RUST_TARGET}
meson install -C _build --tag devel

mkdir ${DEPS}/cgif
$CURL https://github.com/dloebl/cgif/archive/v${VERSION_CGIF}.tar.gz | tar xzC ${DEPS}/cgif --strip-components=1
cd ${DEPS}/cgif
CFLAGS="${CFLAGS} -O3" meson setup _build --default-library=static --buildtype=release --strip --prefix=${TARGET} ${MESON} \
  -Dtests=false
meson install -C _build --tag devel

## Custom lib - imagemagick
mkdir ${DEPS}/imagemagick
$CURL https://github.com/ImageMagick/ImageMagick/archive/refs/tags/${VERSION_IMAGEMAGICK}.tar.gz | tar xzC ${DEPS}/imagemagick --strip-components=1
cd ${DEPS}/imagemagick
./configure --host=${CHOST} --prefix=${TARGET} --enable-static --disable-shared --disable-dependency-tracking --with-xml=/target/include/libxml2 --with-gslib=yes
make install-strip

mkdir ${DEPS}/pdfium
cd ${DEPS}/pdfium
$CURL https://github.com/bblanchon/pdfium-binaries/releases/download/chromium%2F6721/pdfium-linux-x64.tgz | tar xz
cp -r include/* ${TARGET}/include/
cp -r lib/* ${TARGET}/lib/

cat > ${TARGET}/lib/pkgconfig/pdfium.pc << EOF 
prefix=$TARGET
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: pdfium
Description: pdfium
Version: 6721
Requires:
Libs: -L\${libdir} -lpdfium
Cflags: -I\${includedir}
EOF
pkg-config --modversion pdfium
pkg-config --libs pdfium 
pkg-config --cflags pdfium






















mkdir ${DEPS}/vips
$CURL https://github.com/libvips/libvips/releases/download/v${VERSION_VIPS}/vips-$(without_prerelease $VERSION_VIPS).tar.xz | tar xJC ${DEPS}/vips --strip-components=1
cd ${DEPS}/vips
# Use version number in SONAME
$CURL https://gist.githubusercontent.com/lovell/313a6901e9db1bf285f2a1f1180499e4/raw/3988223c7dfa4d22745d9392034b0117abef1446/libvips-cpp-soversion.patch | patch -p1
# Disable HBR support in heifsave
# $CURL https://github.com/libvips/build-win64-mxe/raw/v${VERSION_VIPS}/build/patches/vips-8-heifsave-disable-hbr-support.patch | patch -p1
# Link libvips.so statically into libvips-cpp.so
sed -i'.bak' "s/library('vips'/static_&/" libvips/meson.build
sed -i'.bak' "/version: library_version/{N;d;}" libvips/meson.build
cat libvips/meson.build
if [ "$LINUX" = true ]; then
  # Ensure libvips-cpp.so is linked with -z nodelete
  sed -i'.bak' "/gnu_symbol_visibility: 'hidden',/a link_args: nodelete_link_args," cplusplus/meson.build
  # Ensure symbols from external libs (except for libglib-2.0.a and libgobject-2.0.a) are not exposed
  EXCLUDE_LIBS=$(find ${TARGET}/lib -maxdepth 1 -name '*.a' ! -name 'libglib-2.0.a' ! -name 'libgobject-2.0.a' -printf "-Wl,--exclude-libs=%f ")
  EXCLUDE_LIBS=${EXCLUDE_LIBS%?}
  # Localize the g_param_spec_types symbol to avoid collisions with shared libraries
  # See: https://github.com/lovell/sharp/issues/2535#issuecomment-766400693
  printf "{local:g_param_spec_types;};" > vips.map
  cat vips.map
fi
# Disable building man pages, gettext po files, tools, and (fuzz-)tests
sed -i'.bak' "/subdir('man')/{N;N;N;N;d;}" meson.build
CFLAGS="${CFLAGS} -O3" CXXFLAGS="${CXXFLAGS} -O3" meson setup _build --default-library=shared --buildtype=release --strip --prefix=${TARGET} ${MESON} \
  -Ddeprecated=false -Dexamples=false -Dintrospection=disabled -Dmodules=disabled -Dcfitsio=disabled -Dfftw=disabled -Djpeg-xl=disabled \
  ${WITHOUT_HIGHWAY:+-Dhighway=disabled} -Dorc=disabled -Dmatio=disabled -Dnifti=disabled -Dopenexr=disabled \
  -Dopenjpeg=disabled -Dopenslide=disabled -Dpoppler=disabled -Dquantizr=disabled \
  -Dppm=false -Danalyze=false -Dradiance=false \
  ${LINUX:+-Dcpp_link_args="$LDFLAGS -Wl,-Bsymbolic-functions -Wl,--version-script=$DEPS/vips/vips.map $EXCLUDE_LIBS"}
meson install -C _build --tag runtime,devel

pkg-config --modversion vips
pkg-config --modversion vips-cpp

tar czf ${PACKAGE}/tests/libvips-${VERSION_VIPS}-${PLATFORM}-target.tar.gz ${TARGET}

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
if [ "$LINUX" = true ]; then
  # Check that we really linked with -z nodelete
  readelf -Wd ${VIPS_CPP_DEP} | grep -qF NODELETE || (echo "$VIPS_CPP_DEP was not linked with -z nodelete" && exit 1)
fi
copydeps ${VIPS_CPP_DEP} ${TARGET}/lib-filtered

# Create JSON file of version numbers
cd ${TARGET}
printf "{\n\
  \"aom\": \"${VERSION_AOM}\",\n\
  \"archive\": \"${VERSION_ARCHIVE}\",\n\
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
  \"harfbuzz\": \"${VERSION_HARFBUZZ}\",\n\
  \"heif\": \"${VERSION_HEIF}\",\n\
  \"highway\": \"${VERSION_HWY}\",\n\
  \"imagequant\": \"${VERSION_IMAGEQUANT}\",\n\
  \"lcms\": \"${VERSION_LCMS}\",\n\
  \"mozjpeg\": \"${VERSION_MOZJPEG}\",\n\
  \"pango\": \"${VERSION_PANGO}\",\n\
  \"pixman\": \"${VERSION_PIXMAN}\",\n\
  \"png\": \"${VERSION_PNG}\",\n\
  \"proxy-libintl\": \"${VERSION_PROXY_LIBINTL}\",\n\
  \"rsvg\": \"${VERSION_RSVG}\",\n\
  \"spng\": \"${VERSION_SPNG}\",\n\
  \"tiff\": \"${VERSION_TIFF}\",\n\
  \"vips\": \"${VERSION_VIPS}\",\n\
  \"webp\": \"${VERSION_WEBP}\",\n\
  \"xml2\": \"${VERSION_XML2}\",\n\
  \"zlib\": \"${VERSION_ZLIB}\"\n\
}" >versions.json

# Create the tarball
ls -al lib
ls -al lib-filtered
rm -rf lib
mv lib-filtered lib
echo "Lol" > ImageKit
tar czf ${PACKAGE}/libvips-${VERSION_VIPS}-${PLATFORM}.tar.gz \
  include \
  lib \
  lib64 \
  *.json \
  bin \
  ImageKit \

# Allow tarballs to be read outside container
chmod 644 ${PACKAGE}/libvips-${VERSION_VIPS}-${PLATFORM}.tar.*
