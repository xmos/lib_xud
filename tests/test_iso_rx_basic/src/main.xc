// Copyright 2016-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include "shared.h"

#define EP_COUNT_OUT       (6)
#define EP_COUNT_IN        (6)

#ifndef PKT_LENGTH_START
#define PKT_LENGTH_START   (10)
#endif

#ifndef PKT_LENGTH_END
#define PKT_LENGTH_END     (14)
#endif

#ifndef TEST_EP_NUM
#error
#endif

XUD_EpType epTypeTableOut[EP_COUNT_OUT] = {XUD_EPTYPE_CTL, 
                                            XUD_EPTYPE_ISO, 
                                            XUD_EPTYPE_ISO,
                                            XUD_EPTYPE_ISO,
                                            XUD_EPTYPE_ISO,
                                            XUD_EPTYPE_ISO};

XUD_EpType epTypeTableIn[EP_COUNT_IN] =  {XUD_EPTYPE_CTL, 
                                            XUD_EPTYPE_ISO, 
                                            XUD_EPTYPE_ISO,
                                            XUD_EPTYPE_ISO,
                                            XUD_EPTYPE_ISO,
                                            XUD_EPTYPE_ISO};


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
#else
#error XUD_TEST_SPEED_XX not defined
#endif

            XUD_Main(c_ep_out, EP_COUNT_OUT, c_ep_in, EP_COUNT_IN,
                null, epTypeTableOut, epTypeTableIn,
                speed, XUD_PWR_BUS);
        }

        {
            unsigned fail = TestEp_Rx(c_ep_out[TEST_EP_NUM], TEST_EP_NUM, PKT_LENGTH_START, PKT_LENGTH_END);

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
