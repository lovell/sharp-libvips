# Packaging scripts

libvips and its dependencies are provided as pre-compiled shared libraries
for the most common operating systems and CPU architectures.

During `npm install`, these binaries are fetched as tarballs from
this repository via HTTPS and stored locally within `node_modules/sharp/vendor`.

The base URL can be overridden using the `SHARP_DIST_BASE_URL` environment variable.

## Creating a tarball

Most people will not need to do this; proceed with caution.

Run the top-level [build script](build.sh) without parameters for help.

### Linux

One [build script](build/lin.sh) is used to (cross-)compile
the same shared libraries within multiple containers.

* [x64](linux-x64/Dockerfile)
* [ARMv6](linux-armv6/Dockerfile)
* [ARMv7-A](linux-armv7/Dockerfile)
* [ARMv8-A](linux-armv8/Dockerfile)

### Windows

The output of libvips' [build-win64](https://github.com/jcupitt/build-win64)
"web" target is [post-processed](build/win.sh) within a [container](win32-x64/Dockerfile).

### OS X

See [package-libvips-darwin](https://github.com/lovell/package-libvips-darwin).

## Licences

These scripts are licensed under the terms of the
[Apache 2.0 Licence](https://github.com/lovell/sharp-libvips/blob/master/LICENSE).

The shared libraries contained in the tarballs
are distributed under the terms of the following licences,
all of which are compatible with the Apache 2.0 Licence.

Use of libraries under the terms of the LGPLv3 is via the
"any later version" clause of the LGPLv2 or LGPLv2.1.

| Library       | Used under the terms of                                                                                  |
|---------------|----------------------------------------------------------------------------------------------------------|
| cairo         | Mozilla Public License 2.0                                                                               |
| expat         | MIT Licence                                                                                              |
| fontconfig    | [fontconfig Licence](https://cgit.freedesktop.org/fontconfig/tree/COPYING) (BSD-like)                    |
| freetype      | [freetype Licence](http://git.savannah.gnu.org/cgit/freetype/freetype2.git/tree/docs/FTL.TXT) (BSD-like) |
| fribidi       | LGPLv3
| giflib        | MIT Licence                                                                                              |
| glib          | LGPLv3                                                                                                   |
| harfbuzz      | MIT Licence                                                                                              |
| lcms          | MIT Licence                                                                                              |
| libcroco      | LGPLv3                                                                                                   |
| libexif       | LGPLv3                                                                                                   |
| libffi        | MIT Licence                                                                                              |
| libgsf        | LGPLv3                                                                                                   |
| libjpeg-turbo | [zlib License, IJG License](https://github.com/libjpeg-turbo/libjpeg-turbo/blob/master/LICENSE.md)       |
| libpng        | [libpng License](http://www.libpng.org/pub/png/src/libpng-LICENSE.txt)                                   |
| librsvg       | LGPLv3                                                                                                   |
| libtiff       | [libtiff License](http://www.libtiff.org/misc.html) (BSD-like)                                           |
| libvips       | LGPLv3                                                                                                   |
| libwebp       | New BSD License                                                                                          |
| libxml2       | MIT Licence                                                                                              |
| pango         | LGPLv3                                                                                                   |
| pixman        | MIT Licence                                                                                              |
| zlib          | [zlib Licence](https://github.com/madler/zlib/blob/master/zlib.h)                                        |
