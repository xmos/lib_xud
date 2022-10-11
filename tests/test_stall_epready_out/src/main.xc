// Copyright 2016-2022 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.


#define EP_COUNT_OUT        (6)
#define EP_COUNT_IN         (6)

#ifndef PKT_LENGTH_START
#define PKT_LENGTH_START    (10)
#endif

#ifndef TEST_EP_NUM
#define TEST_EP_NUM         (1)
#endif

#ifndef CTRL_EP_NUM
#define CTRL_EP_NUM         (TEST_EP_NUM + 1)
#endif

#include "xud_shared.h"

/* Endpoint type tables */
XUD_EpType epTypeTableOut[EP_COUNT_OUT] = {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL};
XUD_EpType epTypeTableIn[EP_COUNT_IN] =   {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL};

unsigned test_ctrl(chanend c_ctrl, chanend c)
{
    uint8_t ctrlBuffer[128];
    unsigned length;
    XUD_Result_t result;
    uint32_t failed = 0;

    XUD_ep ep_ctrl = XUD_InitEp(c_ctrl);

    c <: 1;

    XUD_GetBuffer(ep_ctrl, ctrlBuffer, length);
    failed |= (length != PKT_LENGTH_START);

    XUD_ClearStallByAddr(TEST_EP_NUM);

    c <: 1;

    XUD_GetBuffer(ep_ctrl, ctrlBuffer, length);
    failed |= (length != PKT_LENGTH_START);

    XUD_SetStallByAddr(TEST_EP_NUM);

    XUD_GetBuffer(ep_ctrl, ctrlBuffer, length);
    failed |= (length != PKT_LENGTH_START);

    XUD_ClearStallByAddr(TEST_EP_NUM);

    return failed;
}

unsigned test_ep(chanend c_ep_out, chanend c)
{
    uint32_t failed = 0;
    uint8_t outBuffer[128];
    unsigned length;
    XUD_Result_t result;
    unsigned x;

    XUD_ep ep_out = XUD_InitEp(c_ep_out);
    XUD_SetStall(ep_out);

    c :> x;

    /* First test marking EP ready whilst halted
      Then subsequently marked un-halted - this should pause until un-halted */
    XUD_GetBuffer(ep_out, outBuffer, length);

    /* Additional normal OUT transaction */
    XUD_GetBuffer(ep_out, outBuffer, length);

    c :> x;

    /* Next test EP marked ready then subsequently marked as halted */
    XUD_GetBuffer(ep_out, outBuffer, length);

    return failed;

}

unsigned test_func(chanend c_ep_out[EP_COUNT_OUT], chanend c_ep_in[EP_COUNT_IN])
{
    unsigned failedCtrl = 0;
    unsigned failedEp = 0;
    chan c;

    par
    {
        failedCtrl = test_ctrl(c_ep_out[CTRL_EP_NUM], c);
        failedEp = test_ep(c_ep_out[TEST_EP_NUM], c);
    }

    return failedCtrl | failedEp;
}

#include "test_main.xc"
