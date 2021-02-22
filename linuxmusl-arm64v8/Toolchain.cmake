set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_VERSION 1)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

SET(CMAKE_C_COMPILER /root/tools/aarch64-linux-musl-cross/bin/aarch64-linux-musl-gcc)
set(CMAKE_CXX_COMPILER /root/tools/aarch64-linux-musl-cross/bin/aarch64-linux-musl-g++)
SET(CMAKE_AR /root/tools/aarch64-linux-musl-cross/bin/aarch64-linux-musl-ar)
SET(CMAKE_STRIP /root/tools/aarch64-linux-musl-cross/bin/aarch64-linux-musl-strip)
SET(CMAKE_RANLIB /root/tools/aarch64-linux-musl-cross/bin/aarch64-linux-musl-ranlib)

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
