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

* [x64 glibc](linux-x64/Dockerfile)
* [x64 musl](linuxmusl-x64/Dockerfile)
* [ARMv6](linux-armv6/Dockerfile)
* [ARMv7-A](linux-armv7/Dockerfile)
* [ARM64v8-A](linux-arm64v8/Dockerfile)

### Windows

The output of libvips' [build-win64-mxe](https://github.com/libvips/build-win64-mxe)
"web" target is [post-processed](build/win.sh) within multiple containers.

* [win32-ia32](win32-ia32/Dockerfile)
* [win32-x64](win32-x64/Dockerfile)
* [win32-arm64v8](win32-arm64v8/Dockerfile)

### macOS

Uses a macOS virtual machine hosted by GitHub to compile the shared libraries.
The dylib files are compiled within the same build script as Linux.

Depedency paths are modified to be the relative `@rpath` using `install_name_tool`.

## Licences

These scripts are licensed under the terms of the [Apache 2.0 Licence](LICENSE).

The shared libraries contained in the tarballs are distributed under
the terms of [various licences](THIRD-PARTY-NOTICES.md), all of which
are compatible with the Apache 2.0 Licence.
