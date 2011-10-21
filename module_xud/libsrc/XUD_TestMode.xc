#include <xs1.h>
#include <print.h>

#include "XUD_UIFM_Functions.h"
#include "XUD_UIFM_Defines.h"
#include "XUD_USB_Defines.h"
#include "XUD_Support.h"
#include "XUD_TestMode.h"
#include "usb.h"

extern out port reg_write_port;
extern in  port reg_read_port;
extern in  port flag0_port;
extern in  port flag1_port;
extern in  port flag2_port;
extern out port p_usb_txd;
extern port p_usb_rxd;

#define TEST_PACKET_LEN 14
#define T_INTER_TEST_PACKET_us 2
#define  T_INTER_TEST_PACKET (T_INTER_TEST_PACKET_us * XCORE_FREQ_MHz / (REF_CLK_DIVIDER+1))

unsigned int test_packet[TEST_PACKET_LEN] = 
{
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
  XUD_UIFM_RegWrite(reg_write_port, UIFM_REG_PHYCON, 0x15);
  XUD_UIFM_RegWrite(reg_write_port, UIFM_REG_CTRL, 0x4);
  // TestMode remains in J state until exit action is taken (which
  // for a device is power cycle)
  while(1) {
    p_usb_txd <: 1;
  } 
  return 0;
};

int XUD_TestMode_TestK () 
{
  XUD_UIFM_RegWrite(reg_write_port, UIFM_REG_PHYCON, 0x15);
  XUD_UIFM_RegWrite(reg_write_port, UIFM_REG_CTRL, 0x4);
  // TestMode remains in J state until exit action is taken (which
  // for a device is power cycle)
  while(1) {
    p_usb_txd <: 0;
  } 
  return 0;
};

int XUD_TestMode_TestPacket () 
{
	// Repetitively transmit specific test packet forever.
	// Timings must still meet minimum interpacket gap
	// Have to relate KJ pairings to data.
	unsigned i;
	timer test_packet_timer;

#pragma unsafe arrays
	while (1) 
    {
#pragma loop unroll
		for (i=0; i < TEST_PACKET_LEN; i++ ) 
        {
			p_usb_txd <: test_packet[i];
		};
        sync(p_usb_txd);
	    test_packet_timer :> i;
		test_packet_timer when timerafter (i +   T_INTER_TEST_PACKET) :> int _;
	}
	return 0;
}

// runs in XUD thread with interrupt on entering testmode.
int XUD_UsbTestModeHandler() 
{
	unsigned cmd = UsbTestModeHandler_asm();
	
    switch(cmd) 
    {
	    case WINDEX_TEST_J:
		    XUD_UIFM_RegWrite(reg_write_port, UIFM_REG_PHYCON, 0x11);
			while(1) 
            {
			    p_usb_txd <: 0xffffffff;
			}
		    break;
	
        case WINDEX_TEST_K:
		    XUD_UIFM_RegWrite(reg_write_port, UIFM_REG_PHYCON, 0x11);
			while(1) 
            {
				p_usb_txd <: 0;
			}
	        break;
 
        case WINDEX_TEST_SE0_NAK:
	        // NAK every IN packet if the CRC is correct.
	        // Drop into asm to deal with.
		    XUD_UsbTestSE0();
	        break;
        
        case WINDEX_TEST_PACKET:
	        XUD_TestMode_TestPacket();
	        break;
        
        default:
	        break;
	}
	while(1);
    return -1;  // Unreachable
}
