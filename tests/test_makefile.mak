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

SHARED_CODE = ../../shared

COMMON_FLAGS = -DDEBUG_PRINT_ENABLE \
			   -O3 \
			   -g \
			   -I$(SHARED_CODE) \
			   -DUSB_TILE=tile[0] \
			   -DXUD_SIM_XSIM=1 \
			   -Xmapper --retain \
			   -g \
			   -save-temps \
			   $(CFLAGS)

TEST_FLAGS ?=

ifndef TEST_ARCH
$(error TEST_ARCH is not set)
endif

ifndef TEST_FREQ
$(error TEST_FREQ is not set)
endif

ifndef TEST_DTHREADS
$(error TEST_DTHREADS is not set)
endif

ifndef TEST_EP_NUM
$(error TEST_EP_NUM is not set)
endif

ifndef TEST_ADDRESS
$(error TEST_ADDRESS is not set)
endif

ifndef TEST_BUS_SPEED
$(error TEST_BUS_SPEED is not set)
endif

ifeq ($(TEST_BUS_SPEED), FS)
TEST_BUS_SPEED_INT = 1
else
TEST_BUS_SPEED_INT = 2
endif

SOURCE_DIRS = ./src ../shared/src


XCC_FLAGS_$(TEST_ARCH)_$(TEST_FREQ)_$(TEST_DTHREADS)_$(TEST_EP_NUM)_$(TEST_ADDRESS)_$(TEST_BUS_SPEED) = $(TEST_FLAGS) $(COMMON_FLAGS) \
	-DXUD_TEST_SPEED=$(TEST_BUS_SPEED_INT) \
	-DXUD_STARTUP_ADDRESS=$(TEST_ADDRESS) \
	-DTEST_DTHREADS=$(TEST_DTHREADS) \
	-DTEST_EP_NUM=$(TEST_EP_NUM)

# The TARGET variable determines what target system the application is 
# compiled for. It either refers to an XN file in the source directories
# or a valid argument for the --target option when compiling.

TARGET = test_$(TEST_ARCH)_$(TEST_FREQ).xn

# The USED_MODULES variable lists other module used by the application.
USED_MODULES = lib_xud 


#=============================================================================
# The following part of the Makefile includes the common build infrastructure
# for compiling XMOS applications. You should not need to edit below here.

XMOS_MAKE_PATH ?= ../..
include $(XMOS_MAKE_PATH)/xcommon/module_xcommon/build/Makefile.common
