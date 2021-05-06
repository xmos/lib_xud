// Copyright 2016-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
/* lib_xud simple bulk loopback test */
#include <xs1.h>
#include <print.h>
#include <stdio.h>
#include "xud.h"
#include "platform.h"
#include "xc_ptr.h"

#define XUD_EP_COUNT_OUT   5
#define XUD_EP_COUNT_IN    5

/* Endpoint type tables */
XUD_EpType epTypeTableOut[XUD_EP_COUNT_OUT] = {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL};
XUD_EpType epTypeTableIn[XUD_EP_COUNT_IN] =   {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL};

void exit(int);

unsigned char g_rxDataCheck[5] = {0, 0, 0, 0, 0};
unsigned char g_txDataCheck[5] = {0,0,0,0,0,};
unsigned g_txLength[5] = {0,0,0,0,0};


/* Loopback packets forever */
#pragma unsafe arrays
int TestEp_Bulk(chanend c_out1, chanend c_in1)
{
    unsigned int length;
    XUD_Result_t res;

    XUD_ep ep_out1 = XUD_InitEp(c_out1);
    XUD_ep ep_in1  = XUD_InitEp(c_in1);

    /* Buffer for Setup data */
    unsigned char buffer[1024];

    while(1)
    {
        XUD_GetBuffer(ep_out1, buffer, length);
        XUD_SetBuffer(ep_in1, buffer, length);
        
        XUD_GetBuffer(ep_out1, buffer, length);
        XUD_SetBuffer(ep_in1, buffer, length);
    }

}

/* Loopback packet and terminate */
#pragma unsafe arrays
int TestEp_Bulk2(chanend c_out, chanend c_in)
{
    unsigned int length;
    XUD_Result_t res;

    XUD_ep ep_out = XUD_InitEp(c_out);
    XUD_ep ep_in  = XUD_InitEp(c_in);

    /* Buffer for Setup data */
    unsigned char buffer[1024];

    XUD_GetBuffer(ep_out, buffer, length);
    XUD_SetBuffer(ep_in, buffer, length);

    exit(0);
}

#define USB_CORE 0
int main()
{
    chan c_ep_out[XUD_EP_COUNT_OUT], c_ep_in[XUD_EP_COUNT_IN];
    chan c_sync;
    chan c_sync_iso;

    par
    {
        
        XUD_Main( c_ep_out, XUD_EP_COUNT_OUT, c_ep_in, XUD_EP_COUNT_IN,
                                null, epTypeTableOut, epTypeTableIn,
                                null, null, -1, XUD_SPEED_HS, XUD_PWR_BUS);

        TestEp_Bulk(c_ep_out[3], c_ep_in[3]);
        TestEp_Bulk2(c_ep_out[2], c_ep_in[2]);
    }

    return 0;
}
