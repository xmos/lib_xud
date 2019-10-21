// Copyright (c) 2016-2018, XMOS Ltd, All rights reserved
#include <xs1.h>
#include <print.h>
#include <stdio.h>
#include "xud.h"
#include "platform.h"
#include "shared.h"

#define XUD_EP_COUNT_OUT   5
#define XUD_EP_COUNT_IN    8

/* Endpoint type tables */
XUD_EpType epTypeTableOut[XUD_EP_COUNT_OUT] = {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL};
XUD_EpType epTypeTableIn[XUD_EP_COUNT_IN] =   {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, 
                                               XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL};

#define PKT_LENGTH_START 10
#define PKT_LENGTH_END 19


int main()
{
    chan c_ep_out[XUD_EP_COUNT_OUT], c_ep_in[XUD_EP_COUNT_IN];

    par
    {
        
        XUD_Main(c_ep_out, XUD_EP_COUNT_OUT, c_ep_in, XUD_EP_COUNT_IN,
                                null, epTypeTableOut, epTypeTableIn,
                                null, null, -1, XUD_SPEED_HS, XUD_PWR_BUS);

        TestEp_Tx(c_ep_in[3], 3, PKT_LENGTH_START, PKT_LENGTH_END, RUNMODE_LOOP);
        TestEp_Tx(c_ep_in[4], 4, PKT_LENGTH_START, PKT_LENGTH_END, RUNMODE_LOOP);
        TestEp_Tx(c_ep_in[5], 5, PKT_LENGTH_START, PKT_LENGTH_END, RUNMODE_LOOP);

        {
            TestEp_Tx(c_ep_in[6], 6, PKT_LENGTH_START, PKT_LENGTH_END, RUNMODE_DIE);
            XUD_ep ep0 = XUD_InitEp(c_ep_out[0]);
            XUD_Kill(ep0);
            exit(0);
        }

    }

    return 0;
}
