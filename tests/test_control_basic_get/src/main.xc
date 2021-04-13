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


int TestEp_Control(XUD_ep c_ep0_out, XUD_ep c_ep0_in, int epNum)
{
    unsigned int slength;
    unsigned int length;
    XUD_Result_t sres;
    XUD_Result_t res;

    /* Buffer for Setup data */
    unsigned char sbuffer[120];
    unsigned char buffer[120];

    unsafe
    {
        /* Wait for Setup data */
        sres = XUD_GetSetupBuffer(c_ep0_out, sbuffer, slength);

        res = SendTxPacket(c_ep0_in, 10, epNum);

        res = XUD_GetBuffer(c_ep0_out, buffer, length);

        if(length != 0)
        {
            return FAIL_RX_DATAERROR;
        }
      
        /* Do some checking */ 
        if(res != XUD_RES_OKAY)
        {
            return FAIL_RX_BAD_RETURN_CODE;
        }

        if(RxDataCheck(sbuffer, slength, epNum, 8))
        {
            return FAIL_RX_DATAERROR;
        }

        return 0;
    }
}

int main()
{
    chan c_ep_out[XUD_EP_COUNT_OUT], c_ep_in[XUD_EP_COUNT_IN];

    par
    {
        
        XUD_Manager(c_ep_out, XUD_EP_COUNT_OUT, c_ep_in, XUD_EP_COUNT_IN,
                                null, epTypeTableOut, epTypeTableIn,
                                XUD_SPEED_HS, XUD_PWR_BUS);
       
        {
            XUD_ep c_ep0_out = XUD_InitEp(c_ep_out[0]);
            XUD_ep c_ep0_in  = XUD_InitEp(c_ep_in[0]);
           
            int fail = TestEp_Control(c_ep0_out, c_ep0_in, 0);
       
            XUD_Kill(c_ep0_out);
            
            if(fail)
                TerminateFail(fail);
            else
                TerminatePass(fail);    
        }
    }

    return 0;
}
