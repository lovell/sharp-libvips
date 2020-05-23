set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_VERSION 1)
set(CMAKE_SYSTEM_PROCESSOR armv7-a)

SET(CMAKE_C_COMPILER /usr/bin/arm-linux-gnueabihf-gcc)
SET(CMAKE_AR /usr/bin/arm-linux-gnueabihf-gcc-ar)
SET(CMAKE_STRIP /usr/bin/arm-linux-gnueabihf-gcc-strip)
SET(CMAKE_RANLIB /usr/bin/arm-linux-gnueabihf-gcc-ranlib)

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
