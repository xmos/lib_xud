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

#ifndef TEST_EP_NUM
#define TEST_EP_NUM     (1)
#endif

#ifndef CTRL_EP_NUM   
#define CTRL_EP_NUM     (2)
#endif


/* Endpoint type tables */
XUD_EpType epTypeTableOut[XUD_EP_COUNT_OUT] = {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL};
XUD_EpType epTypeTableIn[XUD_EP_COUNT_IN] =   {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL};


unsigned TestEp_Stall(chanend c_ep_out[XUD_EP_COUNT_OUT], chanend c_ep_in[XUD_EP_COUNT_IN])
{
    unsigned failed = 0;
    uint8_t outBuffer[128];
    uint8_t ctrlBuffer[128];
    uint8_t inBuffer[128];
    unsigned length;
    XUD_Result_t result;
    
    for(size_t i = 0; i < sizeof(outBuffer); i++)
        inBuffer[i] = i;

    XUD_ep ep_ctrl = XUD_InitEp(c_ep_out[CTRL_EP_NUM]);

    XUD_ep ep_out = XUD_InitEp(c_ep_out[TEST_EP_NUM]);
    XUD_SetStall(ep_out);
   
    XUD_SetReady_Out(ep_out, outBuffer);
    XUD_SetReady_Out(ep_ctrl, ctrlBuffer);

    unsigned loop = 1;
    while(loop)
    {
        select
        {
            case XUD_GetData_Select(c_ep_out[TEST_EP_NUM], ep_out, length, result):
                loop = 0;
                break;
            
            case XUD_GetData_Select(c_ep_out[CTRL_EP_NUM], ep_ctrl, length, result):
                XUD_ClearStall(ep_out);
                break;
        }
        failed |= (result != XUD_RES_OKAY);
    }

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
            unsigned fail = TestEp_Stall(c_ep_out, c_ep_in);
           
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
