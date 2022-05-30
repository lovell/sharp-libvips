set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_VERSION 1)
set(CMAKE_SYSTEM_PROCESSOR armv6-a)

SET(CMAKE_C_COMPILER arm-rpi-linux-gnueabihf-gcc)
set(CMAKE_CXX_COMPILER arm-rpi-linux-gnueabihf-g++)
SET(CMAKE_AR arm-rpi-linux-gnueabihf-ar)
SET(CMAKE_STRIP arm-rpi-linux-gnueabihf-strip)
SET(CMAKE_RANLIB arm-rpi-linux-gnueabihf-ranlib)

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
