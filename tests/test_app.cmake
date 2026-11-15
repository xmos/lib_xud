# Shared build description of a lib_xud simulator test application.
#
# Include this from a test's CMakeLists.txt, after its project() command and
# after setting TEST_FLAGS to the test's own compiler definitions, and call
# XMOS_REGISTER_APP() there afterwards: XCommon CMake takes the application's
# directory from the file that makes that call. This file declares one build configuration for each
# combination of test parameters, named as the pytest test bench names it:
#
#     <arch>_<core freq>_<dummy threads>_<endpoint>_<address>_<bus speed>_<hbw>
#
# Nothing is built until a test asks for its configuration (Pyxsim.build()).
#
# The core frequency selects the XN file, and XCommon CMake allows one target
# per application, so TEST_FREQ is a cache option: configure one build directory
# for each frequency (build_600, build_800).
set(TEST_ARCH xs3)
set(TEST_FREQ 600 CACHE STRING "Core frequency in MHz; selects shared/test_<arch>_<freq>.xn")
# Every value used by conftest.py's PARAMS or a test module's override of them.
set(TEST_DTHREADS_LIST 0 4 5)
set(TEST_EP_NUM_LIST 0 1 3 4)
set(TEST_ADDRESS_LIST 1)
set(TEST_BUS_SPEED_LIST HS FS)
set(TEST_HBW_EP_LIST hbw_on hbw_off)

# XCommon CMake looks for the XN file in the application's own directory.
configure_file(${CMAKE_CURRENT_LIST_DIR}/shared/test_${TEST_ARCH}_${TEST_FREQ}.xn
               ${CMAKE_CURRENT_SOURCE_DIR}/src/test_${TEST_ARCH}_${TEST_FREQ}.xn COPYONLY)
set(APP_HW_TARGET test_${TEST_ARCH}_${TEST_FREQ}.xn)

set(XMOS_SANDBOX_DIR ${CMAKE_CURRENT_LIST_DIR}/../..)
set(APP_DEPENDENT_MODULES "lib_xud")
set(APP_INCLUDES src ../shared)

set(COMMON_FLAGS -DDEBUG_PRINT_ENABLE -O3 -g -DUSB_TILE=tile[0] -DXUD_SIM_XSIM=1
                 -Xmapper --retain)

# The legacy xcommon build ran Pre-Compilation Analysis on every XC file, and
# XCommon CMake does not unless asked. Without it the XC compiler generates
# different code for lib_xud and the test application (XUD_Main, for one, is
# several times larger), and the HS tests that have the least timing margin at
# 600MHz (device_attach with hbw_on, iso_rx_basic with 5 dummy threads) NAK or
# drop packets.
set(APP_PCA_ENABLE ON)

foreach(dthreads ${TEST_DTHREADS_LIST})
  foreach(ep ${TEST_EP_NUM_LIST})
    foreach(address ${TEST_ADDRESS_LIST})
      foreach(bus_speed ${TEST_BUS_SPEED_LIST})
        foreach(hbw ${TEST_HBW_EP_LIST})
          if(bus_speed STREQUAL FS)
            set(bus_speed_int 1)
            if(hbw STREQUAL hbw_on)
              continue()  # High bandwidth is high speed only.
            endif()
          else()
            set(bus_speed_int 2)
          endif()
          if(hbw STREQUAL hbw_on)
            set(iso_max_txns 2)
          else()
            set(iso_max_txns 1)
          endif()
          set(config ${TEST_ARCH}_${TEST_FREQ}_${dthreads}_${ep}_${address}_${bus_speed}_${hbw})
          set(APP_COMPILER_FLAGS_${config} ${TEST_FLAGS} ${COMMON_FLAGS}
              -DXUD_TEST_SPEED=${bus_speed_int}
              -DXUD_STARTUP_ADDRESS=${address}
              -DTEST_DTHREADS=${dthreads}
              -DTEST_EP_NUM=${ep}
              -DXUD_CORE_CLOCK=${TEST_FREQ}
              -DXUD_USB_ISO_MAX_TXNS_PER_MICROFRAME=${iso_max_txns})
        endforeach()
      endforeach()
    endforeach()
  endforeach()
endforeach()
