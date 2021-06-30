// Copyright 2016-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.


#define EP_COUNT_OUT        (6)
#define EP_COUNT_IN         (6)

#ifndef PKT_LENGTH_START
#define PKT_LENGTH_START    (10)
#endif

#ifndef TEST_EP_NUM
#define TEST_EP_NUM         (1)
#endif

#ifndef CTRL_EP_NUM   
#define CTRL_EP_NUM         (TEST_EP_NUM + 1)
#endif

#include "shared.h"

/* Endpoint type tables */
XUD_EpType epTypeTableOut[EP_COUNT_OUT] = {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL};
XUD_EpType epTypeTableIn[EP_COUNT_IN] =   {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL};

unsigned test_func(chanend c_ep_out[EP_COUNT_OUT], chanend c_ep_in[EP_COUNT_IN])
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
    XUD_ep ep_in = XUD_InitEp(c_ep_in[TEST_EP_NUM]);
    XUD_SetStall(ep_out);
    XUD_SetStall(ep_in);
   
    XUD_SetReady_Out(ep_out, outBuffer);
    XUD_SetReady_In(ep_in, inBuffer, PKT_LENGTH_START);
    XUD_SetReady_Out(ep_ctrl, ctrlBuffer);

    unsigned loop0 = 1;
    unsigned loop1 = 1;
    while(loop0 | loop1)
    {
        select
        {
            case XUD_GetData_Select(c_ep_out[TEST_EP_NUM], ep_out, length, result):
                loop0 = 0;
                break;
            
            case XUD_GetData_Select(c_ep_out[CTRL_EP_NUM], ep_ctrl, length, result):
                XUD_ClearStall(ep_out);
                XUD_ClearStall(ep_in);
                break;
            
            case XUD_SetData_Select(c_ep_in[TEST_EP_NUM], ep_in, result):
                loop1 = 0;
                break;
        }
        failed |= (result != XUD_RES_OKAY);
    }

    return failed;
} 

#include "test_main.xc"
