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

#define XUD_EP_COUNT_OUT   3
#define XUD_EP_COUNT_IN    3


/* Endpoint type tables */
XUD_EpType epTypeTableOut[XUD_EP_COUNT_OUT] = {XUD_EPTYPE_CTL,
                                                XUD_EPTYPE_BUL,
                                                 XUD_EPTYPE_BUL};
XUD_EpType epTypeTableIn[XUD_EP_COUNT_IN] =   {XUD_EPTYPE_CTL, 
                                                XUD_EPTYPE_BUL,
                                                XUD_EPTYPE_BUL};

void Endpoint0( chanend c_ep0_out, chanend c_ep0_in, chanend ?c_usb_test);

void exit(int);

#define FAIL_RX_DATAERROR 0

unsigned fail(int x)
{

    printstr("\nXCORE: ### FAIL ******");
    switch(x)
    {
        case FAIL_RX_DATAERROR:
		    printstr("XCORE RX Data Error\n");

            break;

    }

    exit(1);
}

unsigned char g_rxDataCheck[5] = {0, 0, 0, 0, 0};
unsigned char g_txDataCheck[5] = {0,0,0,0,0,};
unsigned g_txLength[5] = {0,0,0,0,0};


#pragma unsafe arrays
void SendTxPacket(XUD_ep ep, int length, int epNum)
{
    unsigned char buffer[1024];
    unsigned char x;

    for (int i = 0; i < length; i++)
    {
        buffer[i] = g_txDataCheck[epNum]++;
    }

    XUD_SetBuffer(ep, buffer, length);
}

int TestEp_Bulk(chanend c_out, chanend c_in, int epNum)
{
    unsigned int length;
    XUD_Result_t res;

    XUD_ep ep_out = XUD_InitEp(c_out);
    XUD_ep ep_in  = XUD_InitEp(c_in);

    /* Buffer for Setup data */
    unsigned char buffer[1024];

    for(int i = 10; i <= 14; i++)
    {    
        SendTxPacket(ep_in, i, epNum);
    }

    exit(0);
}


#define USB_CORE 0
int main()
{
    chan c_ep_out[XUD_EP_COUNT_OUT], c_ep_in[XUD_EP_COUNT_IN];
    chan c_sync;
    chan c_sync_iso;

    //p_rxDataCheck = char_array_to_xc_ptr(g_rxDataCheck);
    //p_txDataCheck = char_array_to_xc_ptr(g_txDataCheck);
    //p_txLength = array_to_xc_ptr(g_txLength);

    par
    {
        
        XUD_Manager( c_ep_out, XUD_EP_COUNT_OUT, c_ep_in, XUD_EP_COUNT_IN,
                                null, epTypeTableOut, epTypeTableIn,
                                null, null, -1, XUD_SPEED_HS, XUD_PWR_BUS);

        //TestEp_Control(c_ep_out[0], c_ep_in[0], 0);

        TestEp_Bulk(c_ep_out[2], c_ep_in[2], 1);
    }

    return 0;
}
