# The TARGET variable determines what target system the application is 
# compiled for. It either refers to an XN file in the source directories
# or a valid argument for the --target option when compiling.

# In this case, the target depends on the build configuration.
TARGET = XCORE-AI-EXPLORER-NO-DDR.xn

# The APP_NAME variable determines the name of the final .xe file. It should
# not include the .xe postfix. If left blank the name will default to 
# the project name
APP_NAME = app_test_mode

# The flags passed to xcc when building the application
# You can also set the following to override flags for a particular language:
#
#    XCC_XC_FLAGS, XCC_C_FLAGS, XCC_ASM_FLAGS, XCC_CPP_FLAGS
#
# If the variable XCC_MAP_FLAGS is set it overrides the flags passed to
# xcc for the final link (mapping) stage.

# These flags define multiple build configurations - one for each test mode

FLAGS_COMMON = -O3 -report -save-temps -DXUD_BYPASS_RESET -DXUD_TEST_SPEED_HS -DXUD_BYPASS_CONNECT
XCC_FLAGS_TEST_J 		= $(FLAGS_COMMON) -DTEST_MODE=USB_WINDEX_TEST_J
XCC_FLAGS_TEST_K 		= $(FLAGS_COMMON) -DTEST_MODE=USB_WINDEX_TEST_K
XCC_FLAGS_TEST_SE0_NAK 	= $(FLAGS_COMMON) -DTEST_MODE=USB_WINDEX_TEST_SE0_NAK
XCC_FLAGS_TEST_PACKET 	= $(FLAGS_COMMON) -DTEST_MODE=USB_WINDEX_TEST_PACKET

# The USED_MODULES variable lists other module used by the application.
USED_MODULES = lib_xud

#=============================================================================
# The following part of the Makefile includes the common build infrastructure
# for compiling XMOS applications. You should not need to edit below here.

XMOS_MAKE_PATH ?= ../..
include $(XMOS_MAKE_PATH)/xcommon/module_xcommon/build/Makefile.common


