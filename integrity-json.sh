#!/usr/bin/env bash
set -e

LIBVIPS_VERSION=$(cat LIBVIPS_VERSION)

for url in $(curl -sL https://api.github.com/repos/lovell/sharp-libvips/releases | jq -r --arg NAME "v$LIBVIPS_VERSION" '.[] | select(.name == $NAME) | .assets[] | select(.name | contains(".br.integrity")) | .browser_download_url'); do
  PLATFORM_AND_ARCH=$(echo $url | cut -d'.' -f6 | cut -d'-' -f2,3)
  CHECKSUM=$(curl -Ls $url)
  echo "\"$PLATFORM_AND_ARCH\": \"$CHECKSUM\","
done
