#!/usr/bin/env bash
set -e

## Copyright 2017 Lovell Fuller and others.
## SPDX-License-Identifier: Apache-2.0

{
  echo 'Dependency|Version';
  echo '---|---';
  sed 's/=/|/' versions.properties | sed 's/^VERSION_//' | tr 'A-Z_' 'a-z-';
} >release-notes.md
