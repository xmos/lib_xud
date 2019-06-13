#The TARGET variable determines what target system the application is 
# compiled for. It either refers to an XN file in the source directories
# or a valid argument for the --target option when compiling.


# This example runs on the XS-L1 usb audio board. It doesn't use any of
# the audio functionality and just uses the USB functionality of the board
TARGET = XCORE-200-EXPLORER

# The APP_NAME variable determines the name of the final .xe file. It should
# not include the .xe postfix. If left blank the name will default to 
# the project name

APP_NAME = app_test

# The flags passed to xcc when building the application
# You can also set the following to override flags for a particular language:
#
#    XCC_XC_FLAGS, XCC_C_FLAGS, XCC_ASM_FLAGS, XCC_CPP_FLAGS
#
# If the variable XCC_MAP_FLAGS is set it overrides the flags passed to 
# xcc for the final link (mapping) stage.

XCC_FLAGS = -Wall -O3 -report -fsubword-select -DUSB_CORE=0 -DGLX -DTEST_MODE_SUPPORT -DXUD_SERIES_SUPPORT=1
#XCC_FLAGS = -Wall -O2 -report -fsubword-select -DUSB_CORE=1 -DXDK

# The USED_MODULES variable lists other module used by the application. 

USED_MODULES = lib_xud

MODULE_LIBRARIES = xud_u_sim

#=============================================================================
# The following part of the Makefile includes the common build infrastructure
# for compiling XMOS applications. You should not need to edit below here.


# Use the main Makefile from module_xmos_common
XMOS_MAKE_PATH ?= ../..
include $(XMOS_MAKE_PATH)/xcommon/module_xcommon/build/Makefile.common


#all: build

#
# Compile the example
#
#build:
#	xcc -O3 -target=XS1-G4B-FB512 -march=xs1b main.xc -o app_test.xe

#
# Connect the pins together that map to XS1_PORT_1A and XS1_PORT_1B
# NOTE: Requires the testbench to have been built (src/testbenches/ExampleTestbench)
#
run:
	UsbTestbench   '--vcd-tracing "-o trace.vcd -ports -pads"  ./bin/app_test.xe '
	
runtrace:
	UsbTestbench   '-t --vcd-tracing "-o trace.vcd -ports -pads -cycles -instructions"  ./bin/app_test.xe '
	#--vcd-tracing "-o trace.vcd -pads" app_test.xe

#
# This will give a list of the pins which correspond to the ports
#
list:
	xsim --dump-ios app_test.xe
