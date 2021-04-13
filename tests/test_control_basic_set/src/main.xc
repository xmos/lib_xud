// Copyright 2016-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
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
XUD_EpType epTypeTableOut[XUD_EP_COUNT_OUT] = {XUD_EPTYPE_CTL,
                                                XUD_EPTYPE_BUL,
                                                XUD_EPTYPE_ISO,
                                                XUD_EPTYPE_BUL,
                                                 XUD_EPTYPE_BUL};
XUD_EpType epTypeTableIn[XUD_EP_COUNT_IN] =   {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL, XUD_EPTYPE_ISO, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL};


/* Out EP Should receive some data, perform some test process (crc or similar) to check okay */
/* Answers should be responded to in the IN ep */

int TestEp_Control(chanend c_out, chanend c_in, int epNum)
{
    unsigned int slength;
    unsigned int length;
    XUD_Result_t res;

    XUD_ep c_ep0_out = XUD_InitEp(c_out);
    XUD_ep c_ep0_in  = XUD_InitEp(c_in);

    /* Buffer for Setup data */
    unsigned char buffer[120];

    unsafe
    {
        /* Wait for Setup data */
        res = XUD_GetControlBuffer(c_ep0_out, buffer, slength);

        if(slength != 8)
        {
            printintln(length);
            fail(FAIL_RX_DATAERROR);
        }
    
        if(res != XUD_RES_CTL)
        {
            fail(FAIL_RX_EXPECTED_CTL);
        }

        if(RxDataCheck(buffer, slength, epNum))
        {
            fail(FAIL_RX_DATAERROR);
        }

        res = XUD_GetControlBuffer(c_ep0_out, buffer, slength);

        if(slength != 10)
        {
            fail(FAIL_RX_DATAERROR);
        }

        if(RxDataCheck(buffer, length, epNum))
        {
            fail(FAIL_RX_DATAERROR);
        }

        if(res != XUD_RES_OKAY)
        {
            fail(FAIL_RX_BAD_RETURN_CODE);
        }

        /* Send 0 length back */
        res = SendControlPacket(c_ep0_in, 0, epNum);

        if(res != XUD_RES_OKAY)
        {
            fail(FAIL_RX_BAD_RETURN_CODE);
        }

        exit(0);
    }
}

#define USB_CORE 0
int main()
{
    chan c_ep_out[XUD_EP_COUNT_OUT], c_ep_in[XUD_EP_COUNT_IN];

    par
    {
        
        XUD_Manager( c_ep_out, XUD_EP_COUNT_OUT, c_ep_in, XUD_EP_COUNT_IN,
                                null, epTypeTableOut, epTypeTableIn,
                                null, null, -1, XUD_SPEED_HS, XUD_PWR_BUS);

        TestEp_Control(c_ep_out[0], c_ep_in[0], 0);
    }

    return 0;
}
