# The TARGET variable determines what target system the application is 
# compiled for. It either refers to an XN file in the source directories
# or a valid argument for the --target option when compiling.

TARGET = test.xn

# The APP_NAME variable determines the name of the final .xe file. It should
# not include the .xe postfix. If left blank the name will default to 
# the project name

APP_NAME =

# The flags passed to xcc when building the application
# You can also set the following to override flags for a particular language:
#
#    XCC_XC_FLAGS, XCC_C_FLAGS, XCC_ASM_FLAGS, XCC_CPP_FLAGS
#
# If the variable XCC_MAP_FLAGS is set it overrides the flags passed to
# xcc for the final link (mapping) stage.

SHARED_CODE = ../../shared_src

COMMON_FLAGS = -g -report -DDEBUG_PRINT_ENABLE -save-temps -O3 -Xmapper --map -Xmapper MAPFILE -I$(SHARED_CODE) -DUSB_TILE=tile[0] -DSIMULATION -DARCH_L

XCC_FLAGS_xs2       = $(COMMON_FLAGS) -DARCH_X200 -DXUD_SERIES_SUPPORT=XUD_X200_SERIES

XCC_FLAGS_xs1       = $(COMMON_FLAGS) -DARCH_S -DXUD_SERIES_SUPPORT=XUD_U_SERIES



ifeq ($(CONFIG),$(filter $(CONFIG),xs1))
	TARGET = test_xs1.xn
endif

ifeq ($(CONFIG),$(filter $(CONFIG),xs2))
	TARGET = test.xn
endif



# The USED_MODULES variable lists other module used by the application.
USED_MODULES = lib_xud 


#=============================================================================
# The following part of the Makefile includes the common build infrastructure
# for compiling XMOS applications. You should not need to edit below here.

XMOS_MAKE_PATH ?= ../..
include $(XMOS_MAKE_PATH)/xcommon/module_xcommon/build/Makefile.common
