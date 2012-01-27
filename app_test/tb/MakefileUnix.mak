TOOLS_ROOT = /Applications/XMOS_bb16/
#../../..
include $(TOOLS_ROOT)/src/MakefileUnix.mak

ifndef M32
M32 = -m32
endif

OBJS = ExampleTestbench.o

all: $(BINDIR)/ExampleTestbench

$(BINDIR)/ExampleTestbench: $(OBJS)
	$(CPP) $(M32) $(OBJS) -o $(BINDIR)/ExampleTestbench -L$(TOOLS_ROOT)/lib $(LIBS) -lxsidevice $(INCDIRS) $(EXTRALIBS)

%.o: %.cpp
	$(CPP) $(M32) $(CPPFLAGS) -c $< -o $@ -I$(TOOLS_ROOT)/include

clean: 
	rm -rf $(OBJS)
	rm -rf $(BINDIR)/ExampleTestbench.*
