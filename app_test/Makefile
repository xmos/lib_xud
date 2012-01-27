


all: build

#
# Compile the example
#
build:
	xcc -O3 -target=XS1-G4B-FB512 -march=xs1b main.xc -o app_test.xe

#
# Connect the pins together that map to XS1_PORT_1A and XS1_PORT_1B
# NOTE: Requires the testbench to have been built (src/testbenches/ExampleTestbench)
#
run:
	ExampleTestbench   ./app_test.xe 
	
	#--vcd-tracing "-o trace.vcd -pads" app_test.xe

#
# This will give a list of the pins which correspond to the ports
#
list:
	xsim --dump-ios app_test.xe
