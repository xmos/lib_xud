# The TARGET variable determines what target system the application is 
# compiled for. It either refers to an XN file in the source directories
# or a valid argument for the --target option when compiling.

# In this case, the target depends on the build configuration.
ifeq ($(CONFIG),X200)
TARGET = XCORE-200-EXPLORER
else
TARGET = SLICEKIT-U16
endif

# The APP_NAME variable determines the name of the final .xe file. It should
# not include the .xe postfix. If left blank the name will default to 
# the project name
APP_NAME = app_test_and_measurement

# The flags passed to xcc when building the application
# You can also set the following to override flags for a particular language:
#
#    XCC_XC_FLAGS, XCC_C_FLAGS, XCC_ASM_FLAGS, XCC_CPP_FLAGS
#
# If the variable XCC_MAP_FLAGS is set it overrides the flags passed to 
# xcc for the final link (mapping) stage.

# These flags define two build configurations - one for U-series and one for
# the xCORE-200 series.

XCC_FLAGS_U     = -O3 -report -DXUD_SERIES_SUPPORT=XUD_U_SERIES 
XCC_FLAGS_X200  = -O3 -report -DXUD_SERIES_SUPPORT=XUD_X200_SERIES

# The USED_MODULES variable lists other module used by the application. 
USED_MODULES = lib_xud lib_logging

#=============================================================================
# The following part of the Makefile includes the common build infrastructure
# for compiling XMOS applications. You should not need to edit below here.

XMOS_MAKE_PATH ?= ../..
include $(XMOS_MAKE_PATH)/xcommon/module_xcommon/build/Makefile.common


