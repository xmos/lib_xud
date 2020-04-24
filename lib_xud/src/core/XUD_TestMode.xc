// Copyright (c) 2011-2018, XMOS Ltd, All rights reserved
#include <xs1.h>
#include <print.h>

#include "XUD_UIFM_Functions.h"
#include "XUD_USB_Defines.h"
#include "XUD_Support.h"
#include "XUD_TestMode.h"
#include "xud.h"

#if defined(__XS2A__)
#include "xs2_su_registers.h"
#include "XUD_USBTile_Support.h"
extern unsigned get_tile_id(tileref ref);
extern tileref USB_TILE_REF;
#endif

extern in  port flag0_port;
extern in  port flag1_port;
#if !defined(__XS3A__)
extern in  port flag2_port;
#endif

extern out buffered port:32 p_usb_txd;

#define TEST_PACKET_LEN 14
#define T_INTER_TEST_PACKET_us 2
#define  T_INTER_TEST_PACKET (T_INTER_TEST_PACKET_us * REF_CLK_FREQ)

#ifndef XUD_TEST_MODE_SUPPORT_DISABLED
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

// Runs in XUD thread with interrupt on entering testmode.
int XUD_UsbTestModeHandler()
{
    unsigned cmd = UsbTestModeHandler_asm();

    switch(cmd)
    {
        case USB_WINDEX_TEST_J:
            //Function Control Reg. Suspend: 1 Opmode 10

#if defined(__XS3A__)
    #warning Test modes not implemented for XS3A
#elif defined(__XS2A__)
            write_periph_word(USB_TILE_REF, XS1_GLX_PER_UIFM_CHANEND_NUM, XS1_GLX_PER_UIFM_FUNC_CONTROL_NUM, 0b1000);
#endif
            while(1)
            {
                p_usb_txd <: 0xffffffff;
            }
            break;

        case USB_WINDEX_TEST_K:
            //Function Control Reg. Suspend: 1 Opmode 10
#if defined(__XS3A__)
    // TODO
#elif defined(__XS2A__)
            write_periph_word(USB_TILE_REF, XS1_GLX_PER_UIFM_CHANEND_NUM, XS1_GLX_PER_UIFM_FUNC_CONTROL_NUM, 0b1000);
#endif

            while(1)
            {
                p_usb_txd <: 0;
            }
            break;

        case USB_WINDEX_TEST_SE0_NAK:
            // NAK every IN packet if the CRC is correct.
            // Drop into asm to deal with.
            XUD_UsbTestSE0();
            break;

        case USB_WINDEX_TEST_PACKET:
            XUD_TestMode_TestPacket();
            break;

        default:
            break;
    }
    while(1);
    return -1;  // Unreachable
}
#endif
