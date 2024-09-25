cmake_minimum_required(VERSION 3.21)
include($ENV{XMOS_CMAKE_PATH}/xcommon.cmake)
project(app_usb_cdc_edc)

set(APP_HW_TARGET XK-EVK-XU316)

set(APP_INCLUDES src src/eth_tcp)

set(APP_COMPILER_FLAGS -O3 -report -DUSE_XSCOPE=1 -fxscope)

# Ensure all examples share a common set of dependencies
include(${CMAKE_CURRENT_LIST_DIR}/../deps.cmake)

set(XMOS_SANDBOX_DIR ${CMAKE_CURRENT_LIST_DIR}/../../..)

XMOS_REGISTER_APP()
