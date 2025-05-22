// Copyright 2016-2025 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include <string.h>

#ifndef EP_COUNT_OUT
#define EP_COUNT_OUT   (6)
#endif

#ifndef EP_COUNT_IN
#define EP_COUNT_IN    (6)
#endif

#ifndef PKT_LENGTH_START
#define PKT_LENGTH_START 	(12)
#endif

#ifndef PKT_LENGTH_END
#define PKT_LENGTH_END 		(16)
#endif

#ifndef EP_LENGTH
#define EP_LENGTH           (8)
#endif

#define PKT_COUNT           (PKT_LENGTH_END - PKT_LENGTH_START + 1)

#define REQD_BUFFER         (3*(EP_LENGTH+4))  // Buffer length required by XUD_GetBuffer_Finish() for proper error handling
#define EXTRA_BUFFER        (5*(EP_LENGTH+4))  // Extra buffer to check that XUD_GetBuffer_Finish() doesn't overrun the required buffer

#include "xud_shared.h"

XUD_EpType epTypeTableOut[EP_COUNT_OUT] = {XUD_EPTYPE_CTL,
                                                XUD_EPTYPE_ISO,
                                                XUD_EPTYPE_ISO,
                                                XUD_EPTYPE_ISO,
                                                XUD_EPTYPE_ISO,
                                                XUD_EPTYPE_ISO};
XUD_EpType epTypeTableIn[EP_COUNT_IN] =   {XUD_EPTYPE_CTL,
                                                XUD_EPTYPE_ISO,
                                                XUD_EPTYPE_ISO,
                                                XUD_EPTYPE_ISO,
                                                XUD_EPTYPE_ISO,
                                                XUD_EPTYPE_ISO};
extern int TestEp_Rx_RunData(XUD_ep ep_out1, int epNum, int start, int end);

unsigned test_func(chanend c_ep_out[EP_COUNT_OUT], chanend c_ep_in[EP_COUNT_IN])
{
    unsigned int length[PKT_COUNT];

    /* Buffer for Setup data */
    unsigned char buffer[PKT_COUNT][REQD_BUFFER + EXTRA_BUFFER];
    memset(buffer, 0xDE, sizeof(buffer));

    XUD_ep ep_out1 = XUD_InitEp(c_ep_out[TEST_EP_NUM]);
#if USB_HBW_EP
    unsafe {
        XUD_ep_info * ep = (XUD_ep_info*) ep_out1;
        ep->max_len = EP_LENGTH;
    }
#endif

    set_core_fast_mode_on();

    /* Receive a bunch of packets quickly, then check them */
#pragma loop unroll
    for(int i = 0; i < PKT_COUNT; i++)
    {
        XUD_GetBuffer(ep_out1, buffer[i], length[i]);
    }
#pragma loop unroll
    for(int i = 0; i < PKT_COUNT; i++)
    {
        unsafe
        {
            unsigned expectedLength = PKT_LENGTH_START+i;
            unsigned fail = RxDataCheck(buffer[i], length[i], TEST_EP_NUM, expectedLength);
            if (fail)
                return fail;
        }

        for(int offset=REQD_BUFFER; offset<sizeof(buffer[i]); offset++)
        {
            if(buffer[i][offset] != 0xDE)
            {
                printstr("#### Buffer overrun on EP: ");
                printint(TEST_EP_NUM);
                printstr(", Packet ");
                printintln(i);
                printstr("DUT wrote beyond the expected region. Pattern at offset ");
                printint(offset);
                printstrln(" was overwritten. Expected DE, found ");
                printhexln(buffer[i][offset]);

                return FAIL_RX_LENERROR;
            }
        }
    }

    return 0;
}

#include "test_main.xc"
#include "src/shared.xc"


