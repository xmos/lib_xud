// Copyright 2011-2024 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include <xs1.h>

#include "xud.h"
#include "XUD_TestMode.h"

extern XUD_resources_t XUD_resources;

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
                XUD_resources.p_usb_txd <: 0xffffffff;
            }
            break;

        case USB_WINDEX_TEST_K:

            XUD_HAL_EnterMode_PeripheralTestJTestK();

            while(1)
            {
                XUD_resources.p_usb_txd <: 0;
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
                        XUD_resources.p_usb_txd <: test_packet[i];
                    };
                    sync(XUD_resources.p_usb_txd);
                    test_packet_timer :> i;
                    test_packet_timer when timerafter (i + T_INTER_TEST_PACKET) :> int _;
                }
            }
            break;

            case USB_WINDEX_TEST_XMOS_IN_ADDR1:
            {
                XUD_HAL_EnterMode_PeripheralHighSpeed();

                // This isn't a USB test mode but useful for internal testing as the
                // source of IN packets for the receiver sensitivty compliance test.
                // Repetitively transmit specific IN packet forever. (PID = IN, Address = 1, Endpoint = 0, CRC = 0x1D)
                // Not to be used in normal use.
                unsigned i;
                timer test_packet_timer;

                while (1)
                {
                    partout(p_usb_txd, 24, 0xE80169);
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
