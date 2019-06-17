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
#include "xud.h"
#include "platform.h"
#include "xc_ptr.h"

#include "shared.h"

#define XUD_EP_COUNT_OUT   5
#define XUD_EP_COUNT_IN    5

#ifndef PKT_LENGTH_START
#define PKT_LENGTH_START	10
#endif

#ifndef PKT_LENGTH_END
#define PKT_LENGTH_END		19
#endif

/* Endpoint type tables */
XUD_EpType epTypeTableOut[XUD_EP_COUNT_OUT] = {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL};
XUD_EpType epTypeTableIn[XUD_EP_COUNT_IN] =   {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL};

int main()
{
    chan c_ep_out[XUD_EP_COUNT_OUT], c_ep_in[XUD_EP_COUNT_IN];

    par
    {
        
        XUD_Main( c_ep_out, XUD_EP_COUNT_OUT, c_ep_in, XUD_EP_COUNT_IN,
                                null, epTypeTableOut, epTypeTableIn,
                                null, null, -1, XUD_SPEED_HS, XUD_PWR_BUS);

        TestEp_Tx(c_ep_in[3], 3, PKT_LENGTH_START, PKT_LENGTH_END, RUNMODE_DIE);
		
		{
        	TestEp_Rx(c_ep_out[3], 3, PKT_LENGTH_START, PKT_LENGTH_END);
    		XUD_ep ep0 = XUD_InitEp(c_ep_out[0]);
			XUD_Kill(ep0);
			exit(0);	// TODO should be able to move this out of the par
		}
	}

}
