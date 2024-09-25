cmake_minimum_required(VERSION 3.21)
include($ENV{XMOS_CMAKE_PATH}/xcommon.cmake)
project(app_mass_storage)

set(APP_HW_TARGET XK-EVK-XU316)

set(APP_INCLUDES src)

set(APP_COMPILER_FLAGS -O3 -report -DUSE_XSCOPE=1 -fxscope -lflash)

include(${CMAKE_CURRENT_LIST_DIR}/../deps.cmake)

# Ensure all examples share a common set of dependencies
set(XMOS_SANDBOX_DIR ${CMAKE_CURRENT_LIST_DIR}/../../..)

XMOS_REGISTER_APP()
