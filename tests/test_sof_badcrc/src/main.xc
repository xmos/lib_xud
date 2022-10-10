// Copyright 2016-2022 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include <xs1.h>
#include <print.h>
#include <stdio.h>
#include "xud.h"
#include "platform.h"
#include "xud_shared.h"

#define XUD_EP_COUNT_OUT   5
#define XUD_EP_COUNT_IN    5

/* Endpoint type tables */
XUD_EpType epTypeTableOut[XUD_EP_COUNT_OUT] = {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL, XUD_EPTYPE_ISO, XUD_EPTYPE_BUL,XUD_EPTYPE_BUL};
XUD_EpType epTypeTableIn[XUD_EP_COUNT_IN] =   {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL, XUD_EPTYPE_ISO, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL};

void exit(int);

int TestEp(chanend c_out, chanend c_in, int epNum, chanend c_sof)
{
    unsigned int length;
    XUD_Result_t res;

    XUD_ep ep_out = XUD_InitEp(c_out);
    XUD_ep ep_in  = XUD_InitEp(c_in);

    unsigned frames[10];

    /* Buffer for Setup data */
    unsigned char buffer[1024];

    XUD_GetBuffer(ep_out, buffer, length);

    if(length != 10)
    {
        printintln(length);
        return FAIL_RX_LENERROR;
    }

    if(RxDataCheck(buffer, length, epNum, 10))
    {
        return FAIL_RX_DATAERROR;
    }

    /* Receive SOFs */
    /* Host sends 5 SOFs, but one has its CRC nobbled so we should only see 4. */
    for (int i = 0; i< 5; i++)
    {
        if(i == 3)
            continue;

        frames[i] = inuint(c_sof);
    }

    XUD_GetBuffer(ep_out, buffer, length);

    if(length != 11)
    {
        printintln(length);
        return  FAIL_RX_LENERROR;
    }

    if(RxDataCheck(buffer, length, epNum, 11))
    {
        return FAIL_RX_DATAERROR;
    }

    unsigned expectedFrame = 52;

    /* Check frame numbers */
    for (int i = 0 ; i < 5; i++)
    {
        if(i == 3)
            continue;

        if(frames[i] != i+expectedFrame)
        {
            printstr("Expected: ");
            printintln(i+expectedFrame);
            printstr("Received: ");
            printintln(frames[i]);
            return FAIL_RX_FRAMENUMBER;
        }
    }

    return 0;
}


int main()
{
    chan c_ep_out[XUD_EP_COUNT_OUT], c_ep_in[XUD_EP_COUNT_IN];
    chan c_sof;

    par
    {

        XUD_Main( c_ep_out, XUD_EP_COUNT_OUT, c_ep_in, XUD_EP_COUNT_IN,
                                c_sof, epTypeTableOut, epTypeTableIn,
                                XUD_SPEED_HS, XUD_PWR_BUS);

        {
            unsigned fail = TestEp(c_ep_out[1], c_ep_in[1], 1, c_sof);

            if(fail)
                TerminateFail(fail);
            else
                TerminatePass(fail);

            XUD_ep ep0 = XUD_InitEp(c_ep_out[0]);
            XUD_Kill(ep0);
            exit(0);

        }
    }

    return 0;
}
