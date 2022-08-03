// Copyright 2015-2022 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

/* Includes */
#include <platform.h>
#include <xs1.h>
#include <xscope.h>
#include <xccompat.h>

#include "usb_video.h"

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


int main() {

    chan c_ep_out[EP_COUNT_OUT], c_ep_in[EP_COUNT_IN];

    /* 'Par' statement to run the following tasks in parallel */
    par
    {
        on USB_TILE: XUD_Main(c_ep_out, EP_COUNT_OUT, c_ep_in, EP_COUNT_IN,
                      null, epTypeTableOut, epTypeTableIn,
                      XUD_SPEED_HS, XUD_PWR_BUS);

        on USB_TILE: Endpoint0(c_ep_out[0], c_ep_in[0]);

        on USB_TILE: VideoEndpointsHandler(c_ep_in[1], c_ep_in[2]);
    }
    return 0;
}
