// Copyright 2016-2022 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include <xs1.h>
#include <stdio.h>
#include "xud.h"
#include "platform.h"
#include "xud_shared.h"

#define EP_COUNT_OUT   (6)
#define EP_COUNT_IN    (6)

XUD_EpType epTypeTableOut[EP_COUNT_OUT] = {XUD_EPTYPE_CTL,
                                            XUD_EPTYPE_BUL,
                                            XUD_EPTYPE_BUL,
                                            XUD_EPTYPE_BUL,
                                            XUD_EPTYPE_BUL,
                                            XUD_EPTYPE_BUL};

XUD_EpType epTypeTableIn[EP_COUNT_IN] =   {XUD_EPTYPE_CTL,
                                            XUD_EPTYPE_BUL,
                                            XUD_EPTYPE_BUL,
                                            XUD_EPTYPE_BUL,
                                            XUD_EPTYPE_BUL,
                                            XUD_EPTYPE_BUL};

int TestEp_Bulk(chanend c_out, chanend c_in, int epNum, chanend c_out_0)
{
    unsigned int length;
    XUD_Result_t res;

    XUD_ep ep_out_0 = XUD_InitEp(c_out_0);
    XUD_ep ep_out = XUD_InitEp(c_out);
    XUD_ep ep_in  = XUD_InitEp(c_in);

    /* Buffer for Setup data */
    unsigned char buffer[1024];

    for(int i = 10; i <= 14; i++)
    {
        XUD_GetBuffer(ep_out, buffer, length);

        RxDataCheck(buffer, length, epNum, i);
    }

    XUD_Kill(ep_out_0);
    exit(0);
}

int main()
{
    chan c_ep_out[EP_COUNT_OUT], c_ep_in[EP_COUNT_IN];

    par
    {

        XUD_Main( c_ep_out, EP_COUNT_OUT, c_ep_in, EP_COUNT_IN,
                                null, epTypeTableOut, epTypeTableIn,
                                XUD_SPEED_HS, XUD_PWR_BUS);


        TestEp_Bulk(c_ep_out[TEST_EP_NUM], c_ep_in[TEST_EP_NUM], TEST_EP_NUM, c_ep_out[0]);
    }

    return 0;
}
