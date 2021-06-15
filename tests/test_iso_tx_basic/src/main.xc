// Copyright 2016-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
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
#include "shared.h"

#ifndef XUD_EP_COUNT_OUT
#define XUD_EP_COUNT_OUT   (4)
#endif

#ifndef XUD_EP_COUNT_IN
#define XUD_EP_COUNT_IN    (4)
#endif

/* Endpoint type tables */
XUD_EpType epTypeTableOut[XUD_EP_COUNT_OUT] = {XUD_EPTYPE_CTL,
                                                XUD_EPTYPE_BUL,
                                                 XUD_EPTYPE_BUL,
                                                 XUD_EPTYPE_BUL};
XUD_EpType epTypeTableIn[XUD_EP_COUNT_IN] =   {XUD_EPTYPE_CTL, 
                                                XUD_EPTYPE_BUL,
                                                XUD_EPTYPE_BUL,
                                                XUD_EPTYPE_ISO};

int main()
{
    chan c_ep_out[XUD_EP_COUNT_OUT], c_ep_in[XUD_EP_COUNT_IN];
    chan c_dummy[DUMMY_THREAD_COUNT];

    par
    {
        
        XUD_Main(c_ep_out, XUD_EP_COUNT_OUT, c_ep_in, XUD_EP_COUNT_IN,
                                null, epTypeTableOut, epTypeTableIn,
                                XUD_SPEED_HS, XUD_PWR_BUS);
        
		{
			TestEp_Tx(c_ep_in[3], 3, 10, 14, RUNMODE_DIE);
			XUD_ep ep_out_0 = XUD_InitEp(c_ep_out[0]);
			XUD_Kill(ep_out_0);

            for(size_t i = 0; i<DUMMY_THREAD_COUNT; i++)
                outuint(c_dummy[i], 0);
			
            exit(0);
		}
        
        dummyThreads(c_dummy);
    }

    return 0;
}
