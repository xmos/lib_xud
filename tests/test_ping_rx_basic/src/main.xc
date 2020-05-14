// Copyright (c) 2016-2020, XMOS Ltd, All rights reserved
#include "shared.h"

#define XUD_EP_COUNT_OUT   5
#define XUD_EP_COUNT_IN    5

/* Endpoint type tables */
XUD_EpType epTypeTableOut[XUD_EP_COUNT_OUT] = {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL};
XUD_EpType epTypeTableIn[XUD_EP_COUNT_IN] =   {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL};

int TestEp_PingTest(XUD_ep ep_out1, XUD_ep ep_out2, int epNum1, int epNum2)
{
    unsigned int length;

    /* Buffer for Setup data */
    unsigned char buffer[1024];

    int i = 10;
    {    
        XUD_GetBuffer(ep_out1, buffer, length);

        if(RxDataCheck(buffer, length, epNum1, i))
        {
            return FAIL_RX_DATAERROR;
        }

    }
        
	XUD_GetBuffer(ep_out2, buffer, length);

	if(RxDataCheck(buffer, length, epNum2, i))
	{
		return FAIL_RX_DATAERROR;
	}

    // Another packet to EP 1 means we can exit
    XUD_GetBuffer(ep_out1, buffer, length);

    if(RxDataCheck(buffer, length, epNum1, i))
    {
        return FAIL_RX_DATAERROR;
    }
	
	return 0;
}

#define TEST_EP1 1
#define TEST_EP2 2

int main()
{
    chan c_ep_out[XUD_EP_COUNT_OUT], c_ep_in[XUD_EP_COUNT_IN];

    par
    {
        XUD_Main(c_ep_out, XUD_EP_COUNT_OUT, c_ep_in, XUD_EP_COUNT_IN,
                                null, epTypeTableOut, epTypeTableIn,
                                XUD_SPEED_HS, XUD_PWR_BUS);

        {
            XUD_ep ep_out1 = XUD_InitEp(c_ep_out[TEST_EP1]);
            XUD_ep ep_out2 = XUD_InitEp(c_ep_out[TEST_EP2]);
			
            unsigned fail = TestEp_PingTest(ep_out1, ep_out2, TEST_EP1, TEST_EP2);
            
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
