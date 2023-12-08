// Copyright 2015-2022 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

/* Includes */
#include <platform.h>
#include <xs1.h>
#include <xscope.h>
#include <assert.h>
#include <xccompat.h>

#include "usb_video.h"
#include "xud.h"
extern "C"{
    #include "xud_wrapper.h"
}

/* xSCOPE Setup Function */
#if (USE_XSCOPE == 1)
void xscope_user_init(void) {
    xscope_register(0, 0, "", 0, "");
    xscope_config_io(XSCOPE_IO_BASIC); /* Enable fast printing over XTAG */
}
#endif

/* USB Endpoint Defines */
#define EP_COUNT_OUT   1    // 1 OUT EP0
#define EP_COUNT_IN    3    // (1 IN EP0 + 1 INTERRUPT IN EP + 1 ISO IN EP)

/* Endpoint type tables - informs XUD what the transfer types for each Endpoint in use and also
 * if the endpoint wishes to be informed of USB bus resets
 */
XUD_EpType epTypeTableOut[EP_COUNT_OUT] = {XUD_EPTYPE_CTL | XUD_STATUS_ENABLE};
XUD_EpType epTypeTableIn[EP_COUNT_IN] =   {XUD_EPTYPE_CTL | XUD_STATUS_ENABLE, XUD_EPTYPE_INT, XUD_EPTYPE_ISO};

XUD_EpType epTypeTableOut2[EP_COUNT_OUT] = {XUD_EPTYPE_CTL | XUD_STATUS_ENABLE};
XUD_EpType epTypeTableIn2[EP_COUNT_IN] =   {XUD_EPTYPE_CTL | XUD_STATUS_ENABLE, XUD_EPTYPE_INT, XUD_EPTYPE_ISO};


/*
    #define PORT_USB_CLK         on USB_TILE: XS1_PORT_1J
    #define PORT_USB_TXD         on USB_TILE: XS1_PORT_8A
    #define PORT_USB_RXD         on USB_TILE: XS1_PORT_8B
    #define PORT_USB_TX_READYOUT on USB_TILE: XS1_PORT_1K
    #define PORT_USB_TX_READYIN  on USB_TILE: XS1_PORT_1H
    #define PORT_USB_RX_READY    on USB_TILE: XS1_PORT_1I
    #define PORT_USB_FLAG0       on USB_TILE: XS1_PORT_1E
    #define PORT_USB_FLAG1       on USB_TILE: XS1_PORT_1F
*/

XUD_resources_t resources =
{
    on tile[0]: XS1_PORT_1E,            // flag0_port
    on tile[0]: XS1_PORT_1F,            // flag1_port
    null,                               // flag2_port
    on tile[0]: XS1_PORT_1J,            // p_usb_clk
    on tile[0]: XS1_PORT_8A,            // p_usb_txd
    on tile[0]: XS1_PORT_8B,            // p_usb_rxd
    on tile[0]: XS1_PORT_1K,            // tx_readyout
    on tile[0]: XS1_PORT_1H,            // tx_readyin
    on tile[0]: XS1_PORT_1I,            // rx_rdy
    on tile[0]: XS1_CLKBLK_4,           // tx_usb_clk
    on tile[0]: XS1_CLKBLK_5,           // rx_usb_clk
};

XUD_resources_t resources2 =
{
    on tile[2]: XS1_PORT_1E,
    on tile[2]: XS1_PORT_1F,
    null,
    on tile[2]: XS1_PORT_1J,
    on tile[2]: XS1_PORT_8A,
    on tile[2]: XS1_PORT_8B,
    on tile[2]: XS1_PORT_1K,
    on tile[2]: XS1_PORT_1H,
    on tile[2]: XS1_PORT_1I,
    on tile[2]: XS1_CLKBLK_4,
    on tile[2]: XS1_CLKBLK_5,
};

int main() {

    chan c_ep_out[EP_COUNT_OUT], c_ep_in[EP_COUNT_IN];
    chan c_ep_out2[EP_COUNT_OUT], c_ep_in2[EP_COUNT_IN];


    /* 'Par' statement to run the following tasks in parallel */
    par
    {
        on USB_TILE:
                    {
                        init_xud_resources(resources);
                        printstr("XUD\n");
                        XUD_Main(c_ep_out, EP_COUNT_OUT, c_ep_in, EP_COUNT_IN,
                                null, epTypeTableOut, epTypeTableIn,
                                XUD_SPEED_HS, XUD_PWR_BUS);
                    }

        on USB_TILE: Endpoint0(c_ep_out[0], c_ep_in[0], PRODUCT_ID);

        on USB_TILE: VideoEndpointsHandler(c_ep_in[1], c_ep_in[2], 0);

#undef USB_TILE
#define USB_TILE tile[2]

        on USB_TILE: 
                    {
                        init_xud_resources(resources2);
                        printstr("XUD\n");
                        XUD_Main_wrapper(c_ep_out2, EP_COUNT_OUT, c_ep_in2, EP_COUNT_IN,
                                null, epTypeTableOut2, epTypeTableIn2,
                        XUD_SPEED_HS, XUD_PWR_BUS);
                    }

        on USB_TILE: Endpoint0_wrapper(c_ep_out2[0], c_ep_in2[0], PRODUCT_ID + 1);

        on USB_TILE: VideoEndpointsHandler_wrapper(c_ep_in2[1], c_ep_in2[2], 1);


    }
    return 0;
}
