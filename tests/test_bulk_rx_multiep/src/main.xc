// Copyright 2016-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include "shared.h"

#define EP_COUNT_OUT       (7)
#define EP_COUNT_IN        (7)

#define PACKET_LEN_START   (10)
#define PACKET_LEN_END     (19)

/* Check for classes with TEST_EP and traffic EP */
#if TEST_EP_NUM == 4
#error
#endif

#if TEST_EP_NUM == 5
#error
#endif

#if TEST_EP_NUM == 6
#error
#endif

/* Endpoint type tables */
XUD_EpType epTypeTableOut[EP_COUNT_OUT] = {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL};
XUD_EpType epTypeTableIn[EP_COUNT_IN] =   {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL};

int main()
{
    chan c_ep_out[EP_COUNT_OUT], c_ep_in[EP_COUNT_IN];

    par
    {
        
        XUD_Main(c_ep_out, EP_COUNT_OUT, c_ep_in, EP_COUNT_IN,
                                null, epTypeTableOut, epTypeTableIn,
                                XUD_SPEED_HS, XUD_PWR_BUS);

    
        TestEp_Rx(c_ep_out[TEST_EP_NUM], TEST_EP_NUM, PACKET_LEN_START, PACKET_LEN_END);
        TestEp_Rx(c_ep_out[4], 4, PACKET_LEN_START, PACKET_LEN_END);
        TestEp_Rx(c_ep_out[5], 5, PACKET_LEN_START, PACKET_LEN_END);
        {
            XUD_ep ep_out_0 = XUD_InitEp(c_ep_out[0]);
            TestEp_Rx(c_ep_out[6], 6, PACKET_LEN_START, PACKET_LEN_END);
            XUD_Kill(ep_out_0);
            exit(0);
        }
    }

    return 0;
}
