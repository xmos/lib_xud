#TOOLS_ROOT = ../../..
TOOLS_ROOT = $(XMOS_TOOL_PATH)
include $(TOOLS_ROOT)/src/MakefileUnix.mak

OBJS = UsbTestbench.o crc.o

all: $(BINDIR)/UsbTestbench

$(BINDIR)/UsbTestbench: $(OBJS)
	$(CPP) $(OBJS) -o $(BINDIR)/UsbTestbench -L$(TOOLS_ROOT)/lib $(LIBS) -lxsidevice $(INCDIRS) $(EXTRALIBS)

%.o: %.cpp
	$(CPP) $(CPPFLAGS) -c $< -o $@ -I$(TOOLS_ROOT)/include

clean: 
	rm -rf $(OBJS)
	rm -rf $(BINDIR)/UsbTestbench.*
