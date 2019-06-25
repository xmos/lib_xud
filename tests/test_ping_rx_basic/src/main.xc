// Copyright (c) 2016-2018, XMOS Ltd, All rights reserved
/*
 * Test the use of the ExampleTestbench. Test that the value 0 and 1 can be sent
 * in both directions between the ports.
 *
 * NOTE: The src/testbenches/ExampleTestbench must have been compiled for this to run without error.
 *
 */
#include <xs1.h>
#include <print.h>
#include <stdio.h>
#include "xud.h"
#include "platform.h"
#include "xc_ptr.h"

#include "shared.h"

#define XUD_EP_COUNT_OUT   5
#define XUD_EP_COUNT_IN    5

/* Endpoint type tables */
XUD_EpType epTypeTableOut[XUD_EP_COUNT_OUT] = {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL};
XUD_EpType epTypeTableIn[XUD_EP_COUNT_IN] =   {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL};


int TestEp_PingTest(chanend c_out[], int epNum1, int epNum2)
{
    unsigned int length;

    XUD_ep ep_out1 = XUD_InitEp(c_out[epNum1]);
    XUD_ep ep_out2 = XUD_InitEp(c_out[epNum2]);

    /* Buffer for Setup data */
    unsigned char buffer[1024];

    int i = 10;
    {    
        XUD_GetBuffer(ep_out1, buffer, length);

        if(length != i)
        {
            printintln(length);
            fail(FAIL_RX_LENERROR);
        }

        if(RxDataCheck(buffer, length, epNum1))
        {
            fail(FAIL_RX_DATAERROR);
        }

    }
        
	XUD_GetBuffer(ep_out2, buffer, length);

	if(length != i)
	{
		printintln(length);
		fail(FAIL_RX_LENERROR);
	}

	if(RxDataCheck(buffer, length, epNum2))
	{
		fail(FAIL_RX_DATAERROR);
	}

    // Another packet to EP 1 means we can exit
    XUD_GetBuffer(ep_out1, buffer, length);

    if(length != i)
    {
        printintln(length);
        fail(FAIL_RX_LENERROR);
    }

    if(RxDataCheck(buffer, length, epNum1))
    {
        fail(FAIL_RX_DATAERROR);
    }
	
	return 0;
}


int main()
{
    chan c_ep_out[XUD_EP_COUNT_OUT], c_ep_in[XUD_EP_COUNT_IN];

    par
    {
        XUD_Main(c_ep_out, XUD_EP_COUNT_OUT, c_ep_in, XUD_EP_COUNT_IN,
                                null, epTypeTableOut, epTypeTableIn,
                                null, null, -1, XUD_SPEED_HS, XUD_PWR_BUS);

        {
			TestEp_PingTest(c_ep_out, 1, 2);
    		XUD_ep ep_out_0 = XUD_InitEp(c_ep_out[0]);
			XUD_Kill(ep_out_0);
			exit(0);
		}

    }

    return 0;
}
