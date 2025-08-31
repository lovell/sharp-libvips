#!/usr/bin/env bash
set -e

{
  echo 'Dependency|Version';
  echo '---|---';
  sed 's/=/|/' versions.properties | sed 's/^VERSION_//' | tr 'A-Z_' 'a-z-';
} >release-notes.md
