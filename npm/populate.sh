#!/usr/bin/env bash
set -e

LIBVIPS_VERSION=$(cat LIBVIPS_VERSION)
CURL="curl --silent --location"

download_extract() {
  PLATFORM="$1"
  case $1 in
    *ppc64le)
      PACKAGE="${1%??}" # package directory is named as npm/linux-ppc64
      ;;
    *)
      PACKAGE="${1%v[68]}" # remove ARM version
      ;;
  esac
  echo "$PLATFORM -> $PACKAGE"
  rm -rf "npm/$PACKAGE/include" "npm/$PACKAGE/lib"
  $CURL \
    "https://github.com/lovell/sharp-libvips/releases/download/v$LIBVIPS_VERSION/libvips-$LIBVIPS_VERSION-$PLATFORM.tar.gz" | \
    tar xzC "npm/$PACKAGE" --exclude="platform.json"
}

download_cpp() {
  $CURL \
    --remote-name --output-dir "npm/dev/cplusplus" --create-dirs \
    "https://raw.githubusercontent.com/libvips/libvips/v$LIBVIPS_VERSION/cplusplus/$1.cpp"
}

generate_readme() {
  PACKAGE="$1"
  jq -r '("# `" + .name + "`\n\n" + .description + ".\n")' "npm/$PACKAGE/package.json" > "npm/$PACKAGE/README.md"
  echo "## Licensing" >> "npm/$PACKAGE/README.md"
  cat "npm/$PACKAGE/THIRD-PARTY-NOTICES.md" | tail -n +2 >> "npm/$PACKAGE/README.md"
}

generate_index() {
  PACKAGE="$1"
  for dir in include lib cplusplus; do
    if [ -d "npm/$PACKAGE/$dir" ]; then
      echo "module.exports = __dirname;" > "npm/$PACKAGE/$dir/index.js"
    fi
  done
}

remove_unused() {
  PACKAGE="$1"
  if [[ "$PACKAGE" != "dev"* ]]; then
    rm -r "npm/$PACKAGE/include"
    rm "npm/$PACKAGE/THIRD-PARTY-NOTICES.md"
  fi
}

# Download and extract per-platform binaries
PLATFORMS=$(ls platforms --ignore=*armv7 --ignore=win32*)
for platform in $PLATFORMS; do
  download_extract "$platform"
done
download_extract "win32-ia32"
download_extract "win32-x64"

# Common header and source files
cp -r npm/linux-x64/{include,versions.json,THIRD-PARTY-NOTICES.md} npm/dev/
find npm/dev/include/ -maxdepth 1 -type f -links +1 -delete
for source in VConnection VError VImage VInterpolate VRegion vips-operators; do
  download_cpp "$source"
done;

# Generate README files
PACKAGES=$(jq -r '.workspaces[]' "npm/package.json")
for package in $PACKAGES; do
  generate_readme "$package"
  generate_index "$package"
  remove_unused "$package"
done
