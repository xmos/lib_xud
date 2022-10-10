// Copyright 2016-2022 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#define EP_COUNT_OUT       (6)
#define EP_COUNT_IN        (6)

#ifndef PKT_LENGTH_START
#define PKT_LENGTH_START   (10)
#endif

#ifndef CTRL_EP_NUM
#define CTRL_EP_NUM        (TEST_EP_NUM + 1)
#endif

#include "xud_shared.h"

XUD_EpType epTypeTableOut[EP_COUNT_OUT] = {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL};
XUD_EpType epTypeTableIn[EP_COUNT_IN] =   {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL};

unsigned test_func(chanend c_ep_out[EP_COUNT_OUT], chanend c_ep_in[EP_COUNT_IN])
{
    unsigned failed = 0;
    uint8_t outBuffer[128];
    unsigned length;
    XUD_Result_t result;

    /* Stall test EP */
    XUD_ep ep_out = XUD_InitEp(c_ep_out[TEST_EP_NUM]);
    XUD_SetStall(ep_out);

    XUD_ep ep_ctrl = XUD_InitEp(c_ep_out[CTRL_EP_NUM]);

    /* Valid transaction on another EP, clear STALL on the test EP's */
    result = XUD_GetBuffer(ep_ctrl, outBuffer, length);
    failed = (result != XUD_RES_OKAY);

    /* Clear stall on the test EP's */
    XUD_ClearStall(ep_out);

    /* Ensure test EP's now operate as expected */
    result = XUD_GetBuffer(ep_out, outBuffer, length);
    failed |= (result != XUD_RES_OKAY);

    result = XUD_GetBuffer(ep_out, outBuffer, length);
    failed |= (result != XUD_RES_OKAY);

    return failed;
}

#include "test_main.xc"
