cmake_minimum_required(VERSION 3.21)
include($ENV{XMOS_CMAKE_PATH}/xcommon.cmake)
project(lib_xud_examples)

# Main example
add_subdirectory(app_hid_mouse)

