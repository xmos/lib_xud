// Copyright 2016-2022 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include "xud_shared.h"

#define EP_COUNT_OUT       (6)
#define EP_COUNT_IN        (6)

#ifndef PKT_LENGTH_START
#define PKT_LENGTH_START   (10)
#endif

#ifndef PKT_LENGTH_END
#define PKT_LENGTH_END	   (19)
#endif

/* Endpoint type tables */
XUD_EpType epTypeTableOut[EP_COUNT_OUT] = {XUD_EPTYPE_CTL, XUD_EPTYPE_ISO, XUD_EPTYPE_ISO, XUD_EPTYPE_ISO, XUD_EPTYPE_ISO, XUD_EPTYPE_ISO};
XUD_EpType epTypeTableIn[EP_COUNT_IN] =   {XUD_EPTYPE_CTL, XUD_EPTYPE_ISO, XUD_EPTYPE_ISO, XUD_EPTYPE_ISO, XUD_EPTYPE_ISO, XUD_EPTYPE_ISO};

int main()
{
    chan c_ep_out[EP_COUNT_OUT], c_ep_in[EP_COUNT_IN];

    par
    {

        XUD_Main( c_ep_out, EP_COUNT_OUT, c_ep_in, EP_COUNT_IN,
                                null, epTypeTableOut, epTypeTableIn,
                                XUD_SPEED_HS, XUD_PWR_BUS);

        TestEp_Tx(c_ep_in[TEST_EP_NUM], TEST_EP_NUM, PKT_LENGTH_START, PKT_LENGTH_END, RUNMODE_DIE);

		{
        	TestEp_Rx(c_ep_out[TEST_EP_NUM], TEST_EP_NUM, PKT_LENGTH_START, PKT_LENGTH_END);

            /* Allow a little time for Tx data to make it's way of the port - important for FS tests */
            {
                timer t;
                unsigned time;
                t :> time;
                t when timerafter(time + 500) :> int _;
            }

    		XUD_ep ep0 = XUD_InitEp(c_ep_out[0]);
			XUD_Kill(ep0);
			exit(0);	// TODO should be able to move this out of the par
		}
	}

}
