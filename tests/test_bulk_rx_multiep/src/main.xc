// Copyright 2016-2022 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include "xud_shared.h"

#define EP_COUNT_OUT       (7)
#define EP_COUNT_IN        (7)

#define PACKET_LEN_START   (10)
#define PACKET_LEN_END     (19)

/* Check for clashes with TEST_EP and traffic EP */
#if TEST_EP_NUM == 4
#error TEST_EP_NUM clashes with traffic EP
#endif

#if TEST_EP_NUM == 5
#error TEST_EP_NUM clashes with traffic EP
#endif

#if TEST_EP_NUM == 6
#error TEST_EP_NUM clashes with traffic EP
#endif

/* Endpoint type tables */
XUD_EpType epTypeTableOut[EP_COUNT_OUT] = {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL};
XUD_EpType epTypeTableIn[EP_COUNT_IN] =   {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL};

unsigned test_func(chanend c_ep_out[EP_COUNT_OUT], chanend c_ep_in[EP_COUNT_IN])
{
    unsigned fail[4];

    par
    {
        fail[0] = TestEp_Rx(c_ep_out[TEST_EP_NUM], TEST_EP_NUM, PACKET_LEN_START, PACKET_LEN_END);
        fail[1] = TestEp_Rx(c_ep_out[4], 4, PACKET_LEN_START, PACKET_LEN_END);
        fail[2] = TestEp_Rx(c_ep_out[5], 5, PACKET_LEN_START, PACKET_LEN_END);
        fail[3] = TestEp_Rx(c_ep_out[6], 6, PACKET_LEN_START, PACKET_LEN_END);
    }

    for(size_t i = 0; i< 4; i++)
        fail[0] |= fail[i];

    return fail[0];
}

#include "test_main.xc"
