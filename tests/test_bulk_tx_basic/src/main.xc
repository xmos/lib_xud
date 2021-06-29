// Copyright 2016-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include "shared.h"

#ifndef PKT_LENGTH_START
#define PKT_LENGTH_START 	(10)
#endif

#ifndef PKT_LENGTH_END
#define PKT_LENGTH_END 		(19)
#endif

#define EP_COUNT_OUT   		(6)
#define EP_COUNT_IN    		(6)

/* Endpoint type tables */
XUD_EpType epTypeTableOut[EP_COUNT_OUT] = {XUD_EPTYPE_CTL,
                                                XUD_EPTYPE_BUL,
                                                 XUD_EPTYPE_BUL,
                                                 XUD_EPTYPE_BUL,
                                                 XUD_EPTYPE_BUL,
                                                 XUD_EPTYPE_BUL};
XUD_EpType epTypeTableIn[EP_COUNT_IN] =   {XUD_EPTYPE_CTL, 
                                                XUD_EPTYPE_BUL,
                                                XUD_EPTYPE_BUL,
                                                XUD_EPTYPE_BUL,
                                                XUD_EPTYPE_BUL,
                                                XUD_EPTYPE_BUL};

#ifdef XUD_SIM_RTL
int testmain()
#else
int main()
#endif
{
    chan c_ep_out[EP_COUNT_OUT], c_ep_in[EP_COUNT_IN];

    par
    {
        {
#if defined(XUD_TEST_SPEED_FS)
            unsigned speed = XUD_SPEED_FS;
#elif defined(XUD_TEST_SPEED_HS)
            unsigned speed = XUD_SPEED_HS;
#endif
            
            XUD_Main(c_ep_out, EP_COUNT_OUT, c_ep_in, EP_COUNT_IN,
                                null, epTypeTableOut, epTypeTableIn,
                                speed, XUD_PWR_BUS);
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
