// Copyright 2016-2022 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#define EP_COUNT_OUT   		(6)
#define EP_COUNT_IN    		(6)

#include "xud_shared.h"

XUD_EpType epTypeTableOut[EP_COUNT_OUT] = {XUD_EPTYPE_CTL,
                                                XUD_EPTYPE_BUL,
                                                XUD_EPTYPE_BUL,
                                                XUD_EPTYPE_BUL,
                                                XUD_EPTYPE_BUL,
                                                XUD_EPTYPE_BUL};
XUD_EpType epTypeTableIn[EP_COUNT_IN] =   {XUD_EPTYPE_CTL,
                                                XUD_EPTYPE_BUL,
                                                XUD_EPTYPE_BUL,
                                                XUD_EPTYPE_BUL,
                                                XUD_EPTYPE_BUL,
                                                XUD_EPTYPE_BUL};

unsigned test_func(chanend c_ep_out[EP_COUNT_OUT], chanend c_ep_in[EP_COUNT_IN])
{

    XUD_ep ep_out1 = XUD_InitEp(c_ep_out[TEST_EP_NUM]);

    unsigned char buffer[1024];
    unsigned length;

    XUD_GetBuffer(ep_out1, buffer, length);

    /* Just give testbench some time to send some reqs that the DUT should NAK */
    timer t;
    unsigned time;
    t :> time;
    t when timerafter(time + 10000) :> void;
    return 0;
}

#include "test_main.xc"


