// Copyright 2016-2022 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include "xud_shared.h"

#define EP_COUNT_OUT   (6)
#define EP_COUNT_IN    (6)

/* Endpoint type tables */
XUD_EpType epTypeTableOut[EP_COUNT_OUT] = {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL};
XUD_EpType epTypeTableIn[EP_COUNT_IN] =   {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL};

void exit(int);

unsigned TestEp_Bulk(chanend c_out, chanend c_in, int epNum, chanend c_sof)
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
    for (int i = 0; i< 5; i++)
        frames[i] = inuint(c_sof);

    XUD_GetBuffer(ep_out, buffer, length);

    if(length != 11)
    {
        printintln(length);
        return FAIL_RX_LENERROR;
    }

    if(RxDataCheck(buffer, length, epNum, 11))
    {
        return FAIL_RX_DATAERROR;
    }

    unsigned expectedFrame = 52;

    /* Check frame numbers */
    for (int i = 0 ; i < 5; i++)
    {
        if(frames[i] != i+expectedFrame)
        {
            printhexln(i);
            printhexln(frames[i]);
            return FAIL_RX_FRAMENUMBER;
        }
    }

    return 0;
}

int main()
{
    chan c_ep_out[EP_COUNT_OUT], c_ep_in[EP_COUNT_IN];
    chan c_sof;

    par
    {

        XUD_Main( c_ep_out, EP_COUNT_OUT, c_ep_in, EP_COUNT_IN,
                                c_sof, epTypeTableOut, epTypeTableIn,
                                XUD_SPEED_HS, XUD_PWR_BUS);

        {
            unsigned fail = TestEp_Bulk(c_ep_out[TEST_EP_NUM], c_ep_in[TEST_EP_NUM], TEST_EP_NUM, c_sof);

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
