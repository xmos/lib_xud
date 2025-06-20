cmake_minimum_required(VERSION 3.21)
include($ENV{XMOS_CMAKE_PATH}/xcommon.cmake)
project(app_hid_mouse)

set(APP_HW_TARGET XK-EVK-XU316)

set(APP_INCLUDES src)

# Setup two build configurations, one called "c", the other "xc"
set(APP_COMPILER_FLAGS_c -g -O3 -report -fxscope)
set(APP_COMPILER_FLAGS_xc -g -O3 -report -fxscope)

# Setup different source files for the two build configurations
set(SOURCE_FILES_c src/main.c)
set(SOURCE_FILES_xc src/main.xc)

set (APP_DEPENDENT_MODULES    "lib_xud")

set(XMOS_SANDBOX_DIR ${CMAKE_CURRENT_LIST_DIR}/../../..)

XMOS_REGISTER_APP()
