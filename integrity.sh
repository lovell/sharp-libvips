#!/usr/bin/env bash
set -e

# Calculate sha512-based checksum
integrity() {
  CHECKSUM="sha512-$(shasum -a 512 $1 | cut -f1 -d' ' | xxd -r -p | base64 | tr -d '\n')"
  printf "$CHECKSUM $1\n"
  printf "$CHECKSUM" > $1.integrity
}

for tarball in *.tar.gz; do
  integrity $tarball
done
