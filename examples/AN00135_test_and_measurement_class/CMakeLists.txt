cmake_minimum_required(VERSION 3.21)
include($ENV{XMOS_CMAKE_PATH}/xcommon.cmake)
project(app_test_and_measurement)

set(APP_HW_TARGET XK-EVK-XU316)

set(APP_INCLUDES        src
                        src/scpi_parser
                        src/scpi_parser/custom
                        src/scpi_parser/inc
                        src/scpi_parser/inc/scpi
                        )

# Setup two build configurations, one called "c", the other "xc"
set(APP_COMPILER_FLAGS_c -g -O3 -report -fxscope)
set(APP_COMPILER_FLAGS_xc -g -O3 -report -fxscope)

# Setup different source files for the two build configurations
set(SOURCE_FILES_c src/main.c)
set(SOURCE_FILES_xc src/main.xc src/usbtmc_endpoints.xc)

# Ensure all examples share a common set of dependencies
include(${CMAKE_CURRENT_LIST_DIR}/../deps.cmake)

set(XMOS_SANDBOX_DIR ${CMAKE_CURRENT_LIST_DIR}/../../..)

XMOS_REGISTER_APP()
