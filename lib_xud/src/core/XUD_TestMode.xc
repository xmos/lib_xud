// Copyright 2011-2023 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include <xs1.h>

#include "xud.h"
#include "XUD_TestMode.h"

extern out buffered port:32 p_usb_txd;

#define T_INTER_TEST_PACKET_us 2
#define  T_INTER_TEST_PACKET (T_INTER_TEST_PACKET_us * PLATFORM_REFERENCE_MHZ)

#ifndef XUD_TEST_MODE_SUPPORT_DISABLED
unsigned int test_packet[] =
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

// Runs in XUD thread with interrupt on entering testmode.
int XUD_UsbTestModeHandler(unsigned cmd)
{
    switch(cmd)
    {
        case USB_WINDEX_TEST_J:

            XUD_HAL_EnterMode_PeripheralTestJTestK();

            while(1)
            {
                p_usb_txd <: 0xffffffff;
            }
            break;

        case USB_WINDEX_TEST_K:

            XUD_HAL_EnterMode_PeripheralTestJTestK();

            while(1)
            {
                p_usb_txd <: 0;
            }
            break;

        case USB_WINDEX_TEST_SE0_NAK:

            XUD_HAL_EnterMode_PeripheralHighSpeed();

            /* Drop into asm to deal with this mode */
            XUD_UsbTestSE0();
            break;

        case USB_WINDEX_TEST_PACKET:
            {
                XUD_HAL_EnterMode_PeripheralHighSpeed();

                // Repetitively transmit specific test packet forever.
                // Timings must still meet minimum interpacket gap
                // Have to relate KJ pairings to data.
                unsigned i;
                timer test_packet_timer;

#pragma unsafe arrays
                while (1)
                {
#pragma loop unroll
                    for (i=0; i < sizeof(test_packet)/sizeof(test_packet[0]); i++)
                    {
                        p_usb_txd <: test_packet[i];
                    };
                    sync(p_usb_txd);
                    test_packet_timer :> i;
                    test_packet_timer when timerafter (i + T_INTER_TEST_PACKET) :> int _;
                }
            }
            break;

        default:
            break;
    }
    while(1);
    return -1;  // Unreachable
}
#endif
