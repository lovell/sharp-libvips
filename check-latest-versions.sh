#!/usr/bin/env bash
set -e

# Dependency version numbers
source ./versions.properties

# Common options for curl
CURL="curl --silent --location --retry 3 --retry-max-time 30"

# Check for newer versions
ALL_AT_VERSION_LATEST=true
version_latest() {
  VERSION_SELECTOR="stable_versions"
  if [[ "$4" == *"unstable"* ]]; then
    VERSION_SELECTOR="versions"
  fi
  if [[ "$3" == *"/"* ]]; then
    VERSION_LATEST=$(git -c 'versionsort.suffix=-' ls-remote --tags --refs --sort='v:refname' https://github.com/$3.git | awk -F'/' 'END{print $3}' | tr -d 'v')
  else
    VERSION_LATEST=$($CURL "https://release-monitoring.org/api/v2/versions/?project_id=$3" | jq -j ".$VERSION_SELECTOR[0]" | tr '_' '.')
  fi
  if [ "$VERSION_LATEST" != "$2" ]; then
    ALL_AT_VERSION_LATEST=false
    echo "$1 version $2 has been superseded by $VERSION_LATEST"
  fi
  sleep 1
}

version_latest "aom" "$VERSION_AOM" "17628"
version_latest "archive" "$VERSION_ARCHIVE" "libarchive/libarchive"
version_latest "cairo" "$VERSION_CAIRO" "247"
version_latest "cgif" "$VERSION_CGIF" "dloebl/cgif"
version_latest "exif" "$VERSION_EXIF" "libexif/libexif"
version_latest "expat" "$VERSION_EXPAT" "770"
version_latest "ffi" "$VERSION_FFI" "1611"
version_latest "fontconfig" "$VERSION_FONTCONFIG" "827"
version_latest "freetype" "$VERSION_FREETYPE" "854"
version_latest "fribidi" "$VERSION_FRIBIDI" "fribidi/fribidi"
version_latest "glib" "$VERSION_GLIB" "10024" "unstable"
version_latest "harfbuzz" "$VERSION_HARFBUZZ" "1299"
version_latest "heif" "$VERSION_HEIF" "strukturag/libheif"
version_latest "highway" "$VERSION_HWY" "205809"
version_latest "lcms" "$VERSION_LCMS" "9815"
#version_latest "mozjpeg" "$VERSION_MOZJPEG" "mozilla/mozjpeg" # use commit SHA until next tagged release
version_latest "pango" "$VERSION_PANGO" "11783" "unstable"
version_latest "pixman" "$VERSION_PIXMAN" "3648"
version_latest "png" "$VERSION_PNG" "1705"
version_latest "proxy-libintl" "$VERSION_PROXY_LIBINTL" "frida/proxy-libintl"
version_latest "rsvg" "$VERSION_RSVG" "5420" "unstable"
version_latest "tiff" "$VERSION_TIFF" "1738"
version_latest "uhdr" "$VERSION_UHDR" "375187"
version_latest "vips" "$VERSION_VIPS" "5097"
version_latest "webp" "$VERSION_WEBP" "1761"
version_latest "xml2" "$VERSION_XML2" "1783"
version_latest "zlib-ng" "$VERSION_ZLIB_NG" "115592"

if [ "$ALL_AT_VERSION_LATEST" = "false" ]; then exit 1; fi
