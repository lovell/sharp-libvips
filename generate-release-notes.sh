#!/usr/bin/env bash
set -e

## SPDX-FileCopyrightText: 2017 Lovell Fuller and others
## SPDX-License-Identifier: Apache-2.0

{
  echo 'Dependency|Version';
  echo '---|---';
  sed 's/=/|/' versions.properties | sed 's/^VERSION_//' | tr 'A-Z_' 'a-z-';
} >release-notes.md

# Link rsvg version to its Cargo.lock file
source ./versions.properties
sed -i "s/rsvg|$VERSION_RSVG/rsvg|\[$VERSION_RSVG\](https:\/\/gitlab.gnome.org\/GNOME\/librsvg\/-\/raw\/$VERSION_RSVG\/Cargo.lock)/" \
  release-notes.md
