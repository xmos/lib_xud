// Copyright (c) 2016-2018, XMOS Ltd, All rights reserved
/*
 * Test the use of the ExampleTestbench. Test that the value 0 and 1 can be sent
 * in both directions between the ports.
 *
 * NOTE: The src/testbenches/ExampleTestbench must have been compiled for this to run without error.
 *
 */
#include <xs1.h>
#include <print.h>
#include <stdio.h>
#include <platform.h>

#include "xud.h"
#include "shared.h"

#define XUD_EP_COUNT_OUT   5
#define XUD_EP_COUNT_IN    5

#define TEST_EP_NUMBER (3)

/* Endpoint type tables */
XUD_EpType epTypeTableOut[XUD_EP_COUNT_OUT] = {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL};
XUD_EpType epTypeTableIn[XUD_EP_COUNT_IN] =   {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL};

int main()
{
    chan c_ep_out[XUD_EP_COUNT_OUT], c_ep_in[XUD_EP_COUNT_IN];
    par
    {
        XUD_Main(c_ep_out, XUD_EP_COUNT_OUT, c_ep_in, XUD_EP_COUNT_IN,
            null, epTypeTableOut, epTypeTableIn,
            null, null, -1, XUD_SPEED_HS, XUD_PWR_BUS);


        {
            TestEp_Rx(c_ep_out[TEST_EP_NUMBER], TEST_EP_NUMBER, 10, 19);
            XUD_ep ep0 = XUD_InitEp(c_ep_out[0]);
            XUD_Kill(ep0);
            exit(0); // TODO should be able to move this outside of the par{}
        }
    }

    
    return 0;
}
