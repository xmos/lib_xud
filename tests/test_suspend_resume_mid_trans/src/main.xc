// Copyright 2016-2022 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include <xs1.h>
#include <print.h>
#include <stdio.h>
#include "xud.h"
#include "platform.h"
#include "xud_shared.h"

#define XUD_EP_COUNT_OUT    (6)
#define XUD_EP_COUNT_IN     (6)

#ifndef PKT_LENGTH_START
#define PKT_LENGTH_START    (10)
#endif

#ifndef PKT_LENGTH_END
#define PKT_LENGTH_END      (11)
#endif

#ifndef TEST_EP_NUM
#error TEST_EP_NUM not defined
#endif

#ifndef XUD_TEST_SPEED
#error XUD_TEST_SPEED not defined
#endif

/* Endpoint type tables */
XUD_EpType epTypeTableOut[XUD_EP_COUNT_OUT];
XUD_EpType epTypeTableIn[XUD_EP_COUNT_IN];

#ifdef XUD_SIM_RTL
int testmain()
#else
int main()
#endif
{
    chan c_ep_out[XUD_EP_COUNT_OUT], c_ep_in[XUD_EP_COUNT_IN];

    assert((TEST_EP_NUM + 1) < XUD_EP_COUNT_OUT);
    assert((TEST_EP_NUM + 1) < XUD_EP_COUNT_IN);

    epTypeTableOut[0] = XUD_EPTYPE_CTL;
    epTypeTableIn[0] = XUD_EPTYPE_CTL;

    for(int i = 1; i < XUD_EP_COUNT_OUT; i++)
        epTypeTableOut[i] = XUD_EPTYPE_BUL;

    for(int i = 1; i < XUD_EP_COUNT_IN; i++)
        epTypeTableIn[i] = XUD_EPTYPE_BUL;

    epTypeTableOut[TEST_EP_NUM + 1] = XUD_EPTYPE_ISO;
    epTypeTableIn[TEST_EP_NUM + 1] = XUD_EPTYPE_ISO;

    par
    {
        XUD_Main(c_ep_out, XUD_EP_COUNT_OUT, c_ep_in, XUD_EP_COUNT_IN,
            null, epTypeTableOut, epTypeTableIn, XUD_TEST_SPEED, XUD_PWR_BUS);

        {
            unsigned fail = TestEp_Rx(c_ep_out[TEST_EP_NUM], TEST_EP_NUM, PKT_LENGTH_START, PKT_LENGTH_END);
            fail |= TestEp_Rx(c_ep_out[TEST_EP_NUM + 1], TEST_EP_NUM + 1, PKT_LENGTH_START, PKT_LENGTH_END);

            XUD_ep ep0 = XUD_InitEp(c_ep_out[0]);
            XUD_Kill(ep0);

            if(fail)
                TerminateFail(fail);
            else
                TerminatePass(fail);
        }
    }

    return 0;
}
