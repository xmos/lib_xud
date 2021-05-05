// Copyright 2011-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include <xs1.h>
#include <print.h>

#include "XUD_UIFM_Functions.h"
#include "XUD_UIFM_Defines.h"
#include "XUD_USB_Defines.h"
#include "XUD_Support.h"
#include "XUD_TestMode.h"
#include "xud.h"

#ifdef ARCH_S
#include "xs1_su_registers.h"
#endif

#ifdef ARCH_X200
#include "xs2_su_registers.h"
#endif

#if defined(ARCH_S) || defined(ARCH_X200)
#include "XUD_USBTile_Support.h"
extern unsigned get_tile_id(tileref ref);
extern tileref USB_TILE_REF;
#endif

extern in  port flag0_port;
extern in  port flag1_port;
extern in  port flag2_port;
#if defined(ARCH_S) || defined(ARCH_X200)
extern out buffered port:32 p_usb_txd;
#define reg_write_port null
#define reg_read_port null
#else
extern out port reg_write_port;
extern in  port reg_read_port;
extern out port p_usb_txd;
extern port p_usb_rxd;

#endif
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



int XUD_TestMode_TestJ ()
{
#if defined(ARCH_L) || defined(ARCH_X200)

#else
    XUD_UIFM_RegWrite(reg_write_port, UIFM_REG_PHYCON, 0x15);
    XUD_UIFM_RegWrite(reg_write_port, UIFM_REG_CTRL, 0x4);
#endif

    // TestMode remains in J state until exit action is taken (which
    // for a device is power cycle)
    while(1)
    {
        p_usb_txd <: 1;
    }
    return 0;
};

int XUD_TestMode_TestK ()
{
#if defined(ARCH_L) || defined(ARCH_X200)

#else
    XUD_UIFM_RegWrite(reg_write_port, UIFM_REG_PHYCON, 0x15);
    XUD_UIFM_RegWrite(reg_write_port, UIFM_REG_CTRL, 0x4);
#endif

    // TestMode remains in J state until exit action is taken (which
    // for a device is power cycle)
    while(1)
    {
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

// Runs in XUD thread with interrupt on entering testmode.
int XUD_UsbTestModeHandler()
{
    unsigned cmd = UsbTestModeHandler_asm();

    switch(cmd)
    {
        case USB_WINDEX_TEST_J:
            //Function Control Reg. Suspend: 1 Opmode 10
#if defined(ARCH_X200)
            write_periph_word(USB_TILE_REF, XS1_GLX_PER_UIFM_CHANEND_NUM, XS1_GLX_PER_UIFM_FUNC_CONTROL_NUM, 0b1000);
#elif defined(ARCH_S)
            write_periph_word(USB_TILE_REF, XS1_SU_PER_UIFM_CHANEND_NUM, XS1_SU_PER_UIFM_FUNC_CONTROL_NUM, 0b1000);
#else
            XUD_UIFM_RegWrite(reg_write_port, UIFM_REG_PHYCON, 0x11);
#endif

            while(1)
            {
                p_usb_txd <: 0xffffffff;
            }
            break;

        case USB_WINDEX_TEST_K:
            //Function Control Reg. Suspend: 1 Opmode 10
#if defined(ARCH_X200)
            write_periph_word(USB_TILE_REF, XS1_GLX_PER_UIFM_CHANEND_NUM, XS1_GLX_PER_UIFM_FUNC_CONTROL_NUM, 0b1000);
#elif defined(ARCH_S)
            write_periph_word(USB_TILE_REF, XS1_SU_PER_UIFM_CHANEND_NUM, XS1_SU_PER_UIFM_FUNC_CONTROL_NUM, 0b1000);
#else
            XUD_UIFM_RegWrite(reg_write_port, UIFM_REG_PHYCON, 0x11);
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
