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

COMMON_FLAGS = -DDEBUG_PRINT_ENABLE \
			   -O0 \
			   -g \
			   -I$(SHARED_CODE) \
			   -DUSB_TILE=tile[0] \
			   -DXUD_SIM_XSIM=1 \
			   -DXUD_TEST_SPEED_HS=1 \
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

ifndef XUD_STARTUP_ADDRESS
$(error XUD_STARTUP_ADDRESS is not set)
endif

XCC_FLAGS_$(TEST_ARCH)_$(TEST_FREQ)_$(TEST_DTHREADS)_$(TEST_EP_NUM)_$(XUD_STARTUP_ADDRESS)_$(BUS_SPEED) = $(TEST_FLAGS) $(COMMON_FLAGS) 

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
