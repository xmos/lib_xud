// Copyright 2016-2022 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include "xud_shared.h"

#define EP_COUNT_OUT   (5)
#define EP_COUNT_IN    (5)

/* Endpoint type tables */
XUD_EpType epTypeTableOut[EP_COUNT_OUT] = {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL, XUD_EPTYPE_ISO, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL};
XUD_EpType epTypeTableIn[EP_COUNT_IN] =   {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL, XUD_EPTYPE_ISO, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL};

int TestEp_Control(XUD_ep ep0_out, XUD_ep ep0_in, int epNum)
{
    unsigned int slength;
    unsigned int length;

    XUD_Result_t sres;
    XUD_Result_t res;

    unsigned char sbuffer[120];
    unsigned char buffer[120];

    /* Wait for Setup data */
    sres = XUD_GetSetupBuffer(ep0_out, sbuffer, slength);

    res = XUD_GetBuffer(ep0_out, buffer, length);

    res = SendTxPacket(ep0_in, 0, epNum);

    /* Checking for the Setup */
    if(sres != XUD_RES_OKAY)
    {
        return 1;
    }

    if(RxDataCheck(sbuffer, slength, epNum, 8))
    {
        return 1;
    }

    /* Checking for the OUT buffer */
    if(res != XUD_RES_OKAY)
    {
        return 1;
    }

    if(RxDataCheck(buffer, length, epNum, 10))
    {
        return 1;
    }

    sres = XUD_GetSetupBuffer(ep0_out, sbuffer, slength);

    /* Stall the EP(s) as if the request was not recognised */
    XUD_SetStall(ep0_out);
    XUD_SetStall(ep0_in);

    /* Check that EP is un-Halted on a SETUP */
    sres = XUD_GetSetupBuffer(ep0_out, sbuffer, slength);

    res = SendTxPacket(ep0_in, 10, epNum);

    res = XUD_GetBuffer(ep0_out, buffer, length);

    return 0;
}

unsigned test_func(chanend c_ep_out[EP_COUNT_OUT], chanend c_ep_in[EP_COUNT_IN])
{
    XUD_ep ep0_out = XUD_InitEp(c_ep_out[0]);
    XUD_ep ep0_in  = XUD_InitEp(c_ep_in[0]);

    unsigned failed = TestEp_Control(ep0_out, ep0_in, 0);

    XUD_Kill(ep0_out);

    return failed;
}
#include "test_main.xc"
