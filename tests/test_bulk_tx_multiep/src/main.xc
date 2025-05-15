// Copyright 2016-2025 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#define EP_COUNT_OUT       (5)
#define EP_COUNT_IN        (8)

#define PKT_LENGTH_START   (10)
#define PKT_LENGTH_END     (19)

#include "xud_shared.h"

XUD_EpType epTypeTableOut[EP_COUNT_OUT] = {XUD_EPTYPE_CTL,
                                                XUD_EPTYPE_BUL,
                                                XUD_EPTYPE_BUL,
                                                XUD_EPTYPE_BUL,
                                                XUD_EPTYPE_BUL};
XUD_EpType epTypeTableIn[EP_COUNT_IN] =   {XUD_EPTYPE_CTL,
                                                XUD_EPTYPE_BUL,
                                                XUD_EPTYPE_BUL,
                                                XUD_EPTYPE_BUL,
                                                XUD_EPTYPE_BUL,
                                                XUD_EPTYPE_BUL,
                                                XUD_EPTYPE_BUL,
                                                XUD_EPTYPE_BUL};

unsigned test_func(chanend c_ep_out[EP_COUNT_OUT], chanend c_ep_in[EP_COUNT_IN])
{
    unsigned fail[4];

    par
    {
    #if USB_HBW_EP
        fail[0] = TestEp_Tx_Hbw(c_ep_in[3], 3, PKT_LENGTH_START, PKT_LENGTH_END, EP_LENGTH, RUNMODE_DIE);
        fail[1] = TestEp_Tx_Hbw(c_ep_in[4], 4, PKT_LENGTH_START, PKT_LENGTH_END, EP_LENGTH, RUNMODE_DIE);
        fail[2] = TestEp_Tx_Hbw(c_ep_in[5], 5, PKT_LENGTH_START, PKT_LENGTH_END, EP_LENGTH, RUNMODE_DIE);
        fail[3] = TestEp_Tx_Hbw(c_ep_in[6], 6, PKT_LENGTH_START, PKT_LENGTH_END, EP_LENGTH, RUNMODE_DIE);
    #else
        fail[0] = TestEp_Tx(c_ep_in[3], 3, PKT_LENGTH_START, PKT_LENGTH_END, RUNMODE_DIE);
        fail[1] = TestEp_Tx(c_ep_in[4], 4, PKT_LENGTH_START, PKT_LENGTH_END, RUNMODE_DIE);
        fail[2] = TestEp_Tx(c_ep_in[5], 5, PKT_LENGTH_START, PKT_LENGTH_END, RUNMODE_DIE);
        fail[3] = TestEp_Tx(c_ep_in[6], 6, PKT_LENGTH_START, PKT_LENGTH_END, RUNMODE_DIE);
    #endif

    }

    for(size_t i = 0; i < 4; i++)
        fail[0] |= fail[i];

    return fail[0];
}

#include "test_main.xc"
#include "src/shared.xc"


