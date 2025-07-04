// Copyright 2016-2025 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include "xud_shared.h"

#define EP_COUNT_OUT       (6)
#define EP_COUNT_IN        (6)

#ifndef PKT_LENGTH_START
#define PKT_LENGTH_START   (10)
#endif

#ifndef PKT_LENGTH_END
#define PKT_LENGTH_END     (13)
#endif

#include "xud_shared.h"

XUD_EpType epTypeTableOut[EP_COUNT_OUT] = {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL};
XUD_EpType epTypeTableIn[EP_COUNT_IN] =   {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL};

unsigned test_func(chanend c_ep_out[EP_COUNT_OUT], chanend c_ep_in[EP_COUNT_IN])
{
    unsigned fail = TestEp_Rx(c_ep_out[TEST_EP_NUM], TEST_EP_NUM, PKT_LENGTH_START, PKT_LENGTH_END);

    return fail;
}

#include "test_main.xc"

