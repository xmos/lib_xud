#include <xs1.h>
#include <print.h>

#include "XUD_UIFM_Functions.h"
#include "XUD_UIFM_Defines.h"
#include "XUD_USB_Defines.h"
#include "XUD_Support.h"
#include "XUD_TestMode.h"
#include "usb.h"
#include "xud.h"

extern in  port flag0_port;
extern in  port flag1_port;
extern in  port flag2_port;
#ifdef GLX
extern out buffered port:32 p_usb_txd;
#define reg_write_port null
#define reg_read_port null
#else
extern out port reg_write_port;
extern in  port reg_read_port;
extern out port p_usb_txd;
#endif
#define TEST_PACKET_LEN 14
#define T_INTER_TEST_PACKET_us 2
#define  T_INTER_TEST_PACKET (T_INTER_TEST_PACKET_us * XCORE_FREQ_MHz / (REF_CLK_DIVIDER+1))

unsigned int test_packet[TEST_PACKET_LEN] = {
  0x000000c3,
  0x00000000,
  0xaaaa0000,
  0xaaaaaaaa,
  0xeeeeaaaa,
  0xeeeeeeee,
  0xfffeeeee,
  0xffffffff,
  0xffffffff,
  0xbf7fffff,
  0xfbf7efdf,
  0xbf7efcfd,
  0xfbf7efdf,
	0xceb67efd
};



int XUD_TestMode_TestJ () 
{
#ifdef GLX

#else
  XUD_UIFM_RegWrite(reg_write_port, UIFM_REG_PHYCON, 0x15);
  XUD_UIFM_RegWrite(reg_write_port, UIFM_REG_CTRL, 0x4);
#endif
  
  // TestMode remains in J state until exit action is taken (which
  // for a device is power cycle)
  while(1) {
    p_usb_txd <: 1;
  } 
  return 0;
};

int XUD_TestMode_TestK () 
{
#ifdef GLX
#else
  XUD_UIFM_RegWrite(reg_write_port, UIFM_REG_PHYCON, 0x15);
  XUD_UIFM_RegWrite(reg_write_port, UIFM_REG_CTRL, 0x4);
#endif  
  
  // TestMode remains in J state until exit action is taken (which
  // for a device is power cycle)
  while(1) {
    p_usb_txd <: 0;
  } 
  return 0;
};

int XUD_TestMode_TestPacket () {
	// Repetitively transmit specific test packet until reset.
	// Timings must still meet minimum interpacket gap
	// Have to relate KJ pairings to data.
	unsigned i;
	timer test_packet_timer;
	while (1) {
		for (i=0; i<TEST_PACKET_LEN; i++ ) {
			p_usb_txd <: test_packet[i];
		};
		//	p_usb_txd <: 0xceb6;
		//		UsbTestPacketCRC();
	test_packet_timer :> i;
		test_packet_timer when timerafter (i +   T_INTER_TEST_PACKET) :> int _;
	}
	return 0;
}

// runs in XUD thread with interrupt on entering testmode.
int XUD_UsbTestModeHandler(unsigned rxd_port, unsigned rxa_port, chanend c_usb_testmode) {
	// How are channels passed in from an interrup?
	unsigned cmd;
	//	while(1);
	//	printstrln("In test mode handler");
	cmd = UsbTestModeHandler_asm(c_usb_testmode);
	// pause to allow test mode ack to return
	for (int i =0; i < 25000; i++ );
	//	printhexln(cmd);
	switch(cmd) {
	case WINDEX_TEST_J:
#ifdef GLX

#else
		    XUD_UIFM_RegWrite(reg_write_port, UIFM_REG_PHYCON, 0x11);
		//				XUD_UIFM_RegWrite(reg_write_port, UIFM_REG_CTRL, 0x4);
#endif	
    			while(1) {
					p_usb_txd <: 0xffffffff;
				}
		break;
	
 case WINDEX_TEST_K:
#ifdef GLX
#else
		    XUD_UIFM_RegWrite(reg_write_port, UIFM_REG_PHYCON, 0x11);
#endif	
    			//				XUD_UIFM_RegWrite(reg_write_port, UIFM_REG_CTRL, 0x4);
				while(1) {
					p_usb_txd <: 0;
				}
	 break;
 case WINDEX_TEST_SE0_NAK:
	 // NAK every IN packet if the CRC is correct.
	 // Drop into asm to deal with.
	 while(1) {
		 XUD_UsbTestSE0(rxd_port, rxa_port);
	 };
	 break;
 case WINDEX_TEST_PACKET:
	 XUD_TestMode_TestPacket();


	 break;
 default:
#ifdef XUD_DEBUG_MODE
	 printstrln ("ERROR: Unsupported testmode ");
#endif
	 break;
	}
	while(1);
	return -1;  // Unreachable
}
