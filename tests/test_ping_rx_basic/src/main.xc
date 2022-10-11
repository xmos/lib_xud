// Copyright 2016-2022 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include "xud_shared.h"

#define EP_COUNT_OUT   (6)
#define EP_COUNT_IN    (6)

/* Endpoint type tables */
XUD_EpType epTypeTableOut[EP_COUNT_OUT] = {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL};
XUD_EpType epTypeTableIn[EP_COUNT_IN] =   {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL};

int TestEp_PingTest(XUD_ep ep_out1, XUD_ep ep_out2, int epNum1, int epNum2)
{
    unsigned int length;

    unsigned char buffer[1024];

    int i = 10;

    XUD_GetBuffer(ep_out1, buffer, length);

    if(RxDataCheck(buffer, length, epNum1, i))
    {
        return FAIL_RX_DATAERROR;
    }

	XUD_GetBuffer(ep_out2, buffer, length);

	if(RxDataCheck(buffer, length, epNum2, i))
	{
		return FAIL_RX_DATAERROR;
	}

    // Another packet to "ctrl" EP means we can exit
    XUD_GetBuffer(ep_out1, buffer, length);

    if(RxDataCheck(buffer, length, epNum1, i))
    {
        return FAIL_RX_DATAERROR;
    }

	return 0;
}

#define CTRL_EP_NUM (TEST_EP_NUM + 1)

int main()
{
    chan c_ep_out[EP_COUNT_OUT], c_ep_in[EP_COUNT_IN];

    par
    {
        XUD_Main(c_ep_out, EP_COUNT_OUT, c_ep_in, EP_COUNT_IN,
                                null, epTypeTableOut, epTypeTableIn,
                                XUD_SPEED_HS, XUD_PWR_BUS);

        {
            XUD_ep ep_out1 = XUD_InitEp(c_ep_out[CTRL_EP_NUM]);
            XUD_ep ep_out2 = XUD_InitEp(c_ep_out[TEST_EP_NUM]);

            unsigned fail = TestEp_PingTest(ep_out1, ep_out2, CTRL_EP_NUM, TEST_EP_NUM);

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
