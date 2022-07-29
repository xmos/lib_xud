// Copyright 2016-2022 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include <xs1.h>
#include <print.h>
#include <stdio.h>
#include "xud.h"
#include "platform.h"

#define EP_COUNT_OUT   (6)
#define EP_COUNT_IN    (6)

/* Endpoint type tables */
XUD_EpType epTypeTableOut[EP_COUNT_OUT] = {XUD_EPTYPE_CTL, XUD_EPTYPE_ISO, XUD_EPTYPE_ISO, XUD_EPTYPE_ISO, XUD_EPTYPE_ISO, XUD_EPTYPE_ISO};
XUD_EpType epTypeTableIn[EP_COUNT_IN] =   {XUD_EPTYPE_CTL, XUD_EPTYPE_ISO, XUD_EPTYPE_ISO, XUD_EPTYPE_ISO, XUD_EPTYPE_ISO, XUD_EPTYPE_ISO};

void exit(int);

#define KILL_EP_NUM (TEST_EP_NUM +1)

/* Loopback packets forever */
#pragma unsafe arrays
int TestEp_LoopbackForever(chanend c_out1, chanend c_in1)
{
    unsigned int length;
    XUD_Result_t res;

    XUD_ep ep_out1 = XUD_InitEp(c_out1);
    XUD_ep ep_in1  = XUD_InitEp(c_in1);

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
int TestEp_LoopbackOnce(chanend c_out, chanend c_in, chanend c_out_0)
{
    unsigned int length;
    XUD_Result_t res;

    XUD_ep ep_out_0 = XUD_InitEp(c_out_0);
    XUD_ep ep_out = XUD_InitEp(c_out);
    XUD_ep ep_in  = XUD_InitEp(c_in);

    unsigned char buffer[1024];

    XUD_GetBuffer(ep_out, buffer, length);
    XUD_SetBuffer(ep_in, buffer, length);

    /* Allow a little time for Tx data to make it's way of the port - important for FS tests */
    {
        timer t;
        unsigned time;
        t :> time;
        t when timerafter(time + 500) :> int _;
    }

    XUD_Kill(ep_out_0);
    exit(0);
}

int main()
{
    chan c_ep_out[EP_COUNT_OUT], c_ep_in[EP_COUNT_IN];

    par
    {
        XUD_Main(c_ep_out, EP_COUNT_OUT, c_ep_in, EP_COUNT_IN,
                                null, epTypeTableOut, epTypeTableIn,
                                XUD_SPEED_HS, XUD_PWR_BUS);

        TestEp_LoopbackForever(c_ep_out[TEST_EP_NUM], c_ep_in[TEST_EP_NUM]);
        TestEp_LoopbackOnce(c_ep_out[KILL_EP_NUM], c_ep_in[KILL_EP_NUM], c_ep_out[0]);
    }

    return 0;
}
