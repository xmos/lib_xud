// Copyright 2016-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include "shared.h"

#ifndef EP_COUNT_OUT
#define EP_COUNT_OUT   (6)
#endif

#ifndef EP_COUNT_IN
#define EP_COUNT_IN    (6)
#endif

/* Endpoint type tables */
XUD_EpType epTypeTableOut[EP_COUNT_OUT] = {XUD_EPTYPE_CTL,
                                                XUD_EPTYPE_BUL,
                                                 XUD_EPTYPE_BUL,
                                                 XUD_EPTYPE_BUL,
                                                 XUD_EPTYPE_BUL,
                                                 XUD_EPTYPE_BUL};
XUD_EpType epTypeTableIn[EP_COUNT_IN] =   {XUD_EPTYPE_CTL, 
                                                XUD_EPTYPE_ISO,
                                                XUD_EPTYPE_ISO,
                                                XUD_EPTYPE_ISO,
                                                XUD_EPTYPE_ISO,
                                                XUD_EPTYPE_ISO};

int main()
{
    chan c_ep_out[EP_COUNT_OUT], c_ep_in[EP_COUNT_IN];
    //chan c_dummy[DUMMY_THREAD_COUNT];

    par
    {
        
        XUD_Main(c_ep_out, EP_COUNT_OUT, c_ep_in, EP_COUNT_IN,
                                null, epTypeTableOut, epTypeTableIn,
                                XUD_SPEED_HS, XUD_PWR_BUS);
        
		{
			TestEp_Tx(c_ep_in[TEST_EP_NUM], TEST_EP_NUM, 10, 14, RUNMODE_DIE);
			XUD_ep ep_out_0 = XUD_InitEp(c_ep_out[0]);
			XUD_Kill(ep_out_0);

            //for(size_t i = 0; i<DUMMY_THREAD_COUNT; i++)
            //    outuint(c_dummy[i], 0);
			
            exit(0);
		}
        
        //dummyThreads(c_dummy);
    }

    return 0;
}
