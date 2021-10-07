// Copyright 2016-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include <xs1.h>
#include <print.h>
#include <stdio.h>
#include "xud.h"
#include "platform.h"
#include "shared.h"

#define EP_COUNT_OUT       (6)
#define EP_COUNT_IN        (6)

#ifndef PKT_LENGTH_START
#define PKT_LENGTH_START   (10)
#endif

#ifndef TEST_EP_NUM
#error
#endif

#ifndef CTRL_EP_NUM   
#define CTRL_EP_NUM        (TEST_EP_NUM + 1)
#endif


/* Endpoint type tables */
XUD_EpType epTypeTableOut[EP_COUNT_OUT] = {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL};
XUD_EpType epTypeTableIn[EP_COUNT_IN] =   {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL};


unsigned test_func(chanend c_ep_out[EP_COUNT_OUT], chanend c_ep_in[EP_COUNT_IN])
{
    unsigned failed = 0;
    uint8_t outBuffer[128];
    uint8_t inBuffer0[128];
    uint8_t inBuffer1[128];
    unsigned length;
    XUD_Result_t result;
    
    for(size_t i = 0; i < PKT_LENGTH_START; i++)
    {
        inBuffer0[i] = i;
        inBuffer1[i] = i + PKT_LENGTH_START;
    }

    /* Stall EPs */
    XUD_ep ep_out = XUD_InitEp(c_ep_out[TEST_EP_NUM]);
    XUD_SetStall(ep_out);
    
    XUD_ep ep_in = XUD_InitEp(c_ep_in[TEST_EP_NUM]);
    XUD_SetStall(ep_in);

    XUD_ep ep_ctrl = XUD_InitEp(c_ep_out[CTRL_EP_NUM]);

    /* Valid transaction on another EP, clear STALL on the test EP's */
    result = XUD_GetBuffer(ep_ctrl, outBuffer, length);
    failed = (result != XUD_RES_OKAY);
  
    /* Clear stall on the test EP's */ 
    XUD_ClearStall(ep_out);
    XUD_ClearStall(ep_in);

    /* Ensure test EP's now operate as expected */
    result = XUD_GetBuffer(ep_out, outBuffer, length);
    failed |= (result != XUD_RES_OKAY);
    
    result = XUD_SetBuffer(ep_in, inBuffer0, PKT_LENGTH_START);
    failed |= (result != XUD_RES_OKAY);

    /* Stall both EP's using Addr */  
    XUD_SetStallByAddr(TEST_EP_NUM);
    XUD_SetStallByAddr(TEST_EP_NUM | 0x80);

    /* Valid transaction on another EP, clear STALL on the test EP's */
    result = XUD_GetBuffer(ep_ctrl, outBuffer, length);
    failed = (result != XUD_RES_OKAY);

    /* Clear stall on both EPs using Addr */
    XUD_ClearStallByAddr(TEST_EP_NUM);
    XUD_ClearStallByAddr(TEST_EP_NUM | 0x80);

    /* Ensure test EP's now operate as expected */
    result = XUD_GetBuffer(ep_out, outBuffer, length);
    failed |= (result != XUD_RES_OKAY);
    
    result = XUD_SetBuffer(ep_in, inBuffer1, PKT_LENGTH_START);
    failed |= (result != XUD_RES_OKAY);

    return failed;
} 

#include "test_main.xc"


