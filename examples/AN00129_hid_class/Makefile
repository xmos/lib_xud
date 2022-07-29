# The APP_NAME variable determines the name of the final .xe file. It should
# not include the .xe postfix. If left blank the name will default to
# the project name

APP_NAME = app_hid_mouse_demo

# The flags passed to xcc when building the application
# You can also set the following to override flags for a particular language:
#
#    XCC_XC_FLAGS, XCC_C_FLAGS, XCC_ASM_FLAGS, XCC_CPP_FLAGS
#
# If the variable XCC_MAP_FLAGS is set it overrides the flags passed to
# xcc for the final link (mapping) stage.

# These flags define two build configurations - one for xCORE-200 and one for
# the xCORE.AI series.
BUILD_FLAGS = -O3 -report -fxscope

XCC_FLAGS_200 = $(BUILD_FLAGS)
XCC_FLAGS_AI = $(BUILD_FLAGS)
XCC_FLAGS_AI_C = $(BUILD_FLAGS)

USED_MODULES = lib_xud

# The TARGET variable determines what target system the application is 
# compiled for. It either refers to an XN file in the source directories
# or a valid argument for the --target option when compiling.

# In this case, the target depends on the build configuration.
ifeq ($(CONFIG),AI)
TARGET = XCORE-AI-EXPLORER
EXCLUDE_FILES = main.c
else ifeq ($(CONFIG),AI_C)
TARGET = XCORE-AI-EXPLORER
EXCLUDE_FILES = main.xc \
				endpoint0.xc
else
TARGET = XCORE-200-EXPLORER
EXCLUDE_FILES = main.c
endif
#=============================================================================
# The following part of the Makefile includes the common build infrastructure
# for compiling XMOS applications. You should not need to edit below here.

XMOS_MAKE_PATH ?= ../..
include $(XMOS_MAKE_PATH)/xcommon/module_xcommon/build/Makefile.common
