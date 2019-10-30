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

#ifndef TEST_EP_NUM
#define TEST_EP_NUM   1
#endif

#ifndef PKT_LENGTH_START
#define PKT_LENGTH_START 10
#endif

#ifndef PKT_LENGTH_END
#define PKT_LENGTH_END 13
#endif

#define XUD_EP_COUNT_OUT   4
#define XUD_EP_COUNT_IN    4

/* Endpoint type tables */
XUD_EpType epTypeTableOut[XUD_EP_COUNT_OUT] = {XUD_EPTYPE_CTL,
                                                XUD_EPTYPE_BUL,
                                                 XUD_EPTYPE_BUL,
                                                 XUD_EPTYPE_BUL};
XUD_EpType epTypeTableIn[XUD_EP_COUNT_IN] =   {XUD_EPTYPE_CTL, 
                                                XUD_EPTYPE_BUL,
                                                XUD_EPTYPE_BUL,
                                                XUD_EPTYPE_ISO};

#ifdef XUD_SIM_RTL
int testmain()
#else
int main()
#endif
{
    chan c_ep_out[XUD_EP_COUNT_OUT], c_ep_in[XUD_EP_COUNT_IN];

    par
    {
        {
            #if defined(XUD_TEST_SPEED_FS)
            unsigned speed = XUD_SPEED_FS;
            #elif defined(XUD_TEST_SPEED_HS)
            unsigned speed = XUD_SPEED_HS;
            #endif
            
            // TODO test is running at 400MHz 
            XUD_Main(c_ep_out, XUD_EP_COUNT_OUT, c_ep_in, XUD_EP_COUNT_IN,
                                null, epTypeTableOut, epTypeTableIn,
                                null, null, -1, speed, XUD_PWR_BUS);
        }

		{
			unsigned fail = TestEp_Tx(c_ep_in[TEST_EP_NUM], TEST_EP_NUM, PKT_LENGTH_START, PKT_LENGTH_END, RUNMODE_DIE);

#ifdef XUD_SIM_RTL
            /* Note, this test relies on checking at the host side */

            if(fail)
                TerminateFail(fail);
            else
                TerminatePass(fail);    
#endif
			
            XUD_ep ep_out_0 = XUD_InitEp(c_ep_out[0]);
			XUD_Kill(ep_out_0);
			exit(0);
		}
    }

    return 0;
}
