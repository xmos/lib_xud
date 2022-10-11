// Copyright 2016-2022 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#define EP_COUNT_OUT        (7)
#define EP_COUNT_IN         (7)

#ifndef PKT_LENGTH_START
#define PKT_LENGTH_START    (10)
#endif

#ifndef PKT_LENGTH_END
#define PKT_LENGTH_END      (19)
#endif

#include "xud_shared.h"

/* The test bench will use either ep 1, 2, or 4 for the "test EP" */

XUD_EpType epTypeTableOut[EP_COUNT_OUT] = {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_DIS, XUD_EPTYPE_BUL, XUD_EPTYPE_DIS, XUD_EPTYPE_BUL};
XUD_EpType epTypeTableIn[EP_COUNT_IN] =   {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_DIS, XUD_EPTYPE_BUL, XUD_EPTYPE_DIS, XUD_EPTYPE_BUL};

unsigned test_func(chanend c_ep_out[EP_COUNT_OUT], chanend c_ep_in[EP_COUNT_IN])
{
    unsigned failed = 0;
    uint8_t outBuffer0[128];
    uint8_t inBuffer0[128];
    unsigned length;
    XUD_Result_t result;

    for(size_t i = 0; i < PKT_LENGTH_START; i++)
    {
        inBuffer0[i] = i;
    }

    XUD_ep ep_out = XUD_InitEp(c_ep_out[TEST_EP_NUM]);
    XUD_ep ep_in = XUD_InitEp(c_ep_in[TEST_EP_NUM]);

    result = XUD_GetBuffer(ep_out, outBuffer0, length);
    failed = (result != XUD_RES_OKAY);

    result = XUD_SetBuffer(ep_in, inBuffer0, PKT_LENGTH_START);
    failed |= (result != XUD_RES_OKAY);

    result = XUD_GetBuffer(ep_out, outBuffer0, length);
    failed = (result != XUD_RES_OKAY);

    return failed;
}

#include "test_main.xc"

