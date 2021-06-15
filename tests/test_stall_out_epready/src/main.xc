// Copyright 2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include <xs1.h>
#include <print.h>
#include <stdio.h>
#include "xud.h"
#include "platform.h"
#include "shared.h"

#define XUD_EP_COUNT_OUT   5
#define XUD_EP_COUNT_IN    5

#ifndef PKT_LENGTH_START
#define PKT_LENGTH_START 10
#endif

#ifndef PKT_LENGTH_END
#define PKT_LENGTH_END 19
#endif

#ifndef TEST_EP_NUM
#define TEST_EP_NUM     (2)
#endif

#ifndef CTRL_EP_NUM   
#define CTRL_EP_NUM     (3)
#endif


/* Endpoint type tables */
XUD_EpType epTypeTableOut[XUD_EP_COUNT_OUT] = {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL};
XUD_EpType epTypeTableIn[XUD_EP_COUNT_IN] =   {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL};


unsigned TestEp_Stall(chanend c_ep_out[XUD_EP_COUNT_OUT], unsigned epNum)
{
    unsigned failed = 0;
    uint8_t buffer[1024];
    unsigned length;

    /* Stall EP */
    XUD_ep ep = XUD_InitEp(c_ep_out[TEST_EP_NUM]);
    XUD_SetStall(ep);

    /* EP marked ready, XUD should still STALL */
    XUD_Result_t result0 = XUD_GetBuffer(ep, buffer, length);

    XUD_ep ep_ctrl = XUD_InitEp(c_ep_out[CTRL_EP_NUM]);

    XUD_Result_t result1 = XUD_GetBuffer(ep_ctrl, buffer, length);

    failed = (result0 != XUD_RES_OKAY) | (result1 != XUD_RES_OKAY);

    return failed;
} 


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
#else
#error XUD_TEST_SPEED_XX not defined
#endif

            XUD_Main(c_ep_out, XUD_EP_COUNT_OUT, c_ep_in, XUD_EP_COUNT_IN,
                null, epTypeTableOut, epTypeTableIn, speed, XUD_PWR_BUS);
        }

        {
            unsigned fail = TestEp_Stall(c_ep_out, TEST_EP_NUM);
           
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
