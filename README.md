# Packaging scripts

libvips and its dependencies are provided as pre-compiled shared libraries
for the most common operating systems and CPU architectures.

During `npm install`, these binaries are fetched as tarballs from
this repository via HTTPS and stored locally within `node_modules/sharp/vendor`.

The base URL can be overridden using the
`npm_config_sharp_libvips_binary_host` environment variable.

https://sharp.pixelplumbing.com/install#custom-prebuilt-binaries

## Creating a tarball

Most people will not need to do this; proceed with caution.

Run the top-level [build script](build.sh) without parameters for help.

### Linux

One [build script](build/lin.sh) is used to (cross-)compile
the same shared libraries within multiple containers.

* [x64 glibc](platforms/linux-x64/Dockerfile)
* [x64 musl](platforms/linuxmusl-x64/Dockerfile)
* [ARMv6 glibc](platforms/linux-armv6/Dockerfile)
* [ARMv7-A glibc](platforms/linux-armv7/Dockerfile)
* [ARM64v8-A glibc](platforms/linux-arm64v8/Dockerfile)
* [ARM64v8-A musl](platforms/linuxmusl-arm64v8/Dockerfile)
* [s390x glibc](platforms/linux-s390x/Dockerfile)

### Windows

The output of libvips' [build-win64-mxe](https://github.com/libvips/build-win64-mxe)
static "web" releases are [post-processed](build/win.sh) within a [container](platforms/win32/Dockerfile).

### macOS

Uses a macOS virtual machine hosted by GitHub to compile the shared libraries.
The dylib files are compiled within the same build script as Linux.

* x64 (native)
* ARM64 (cross-compiled)

Dependency paths are modified to use the relative `@rpath` with `install_name_tool`.

## Licences

These scripts are licensed under the terms of the [Apache 2.0 Licence](LICENSE).

The shared libraries contained in the tarballs are distributed under
the terms of [various licences](THIRD-PARTY-NOTICES.md), all of which
are compatible with the Apache 2.0 Licence.
