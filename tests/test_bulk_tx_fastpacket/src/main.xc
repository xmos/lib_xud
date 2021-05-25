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

#define XUD_EP_COUNT_OUT   5
#define XUD_EP_COUNT_IN    5

/* Endpoint type tables */
XUD_EpType epTypeTableOut[XUD_EP_COUNT_OUT] = {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL};
XUD_EpType epTypeTableIn[XUD_EP_COUNT_IN] =   {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL};

void Endpoint0( chanend c_ep0_out, chanend c_ep0_in, chanend ?c_usb_test);

void exit(int);

#define FAIL_RX_DATAERROR 0
#define FAIL_RX_LENERROR 1

#define PKT_COUNT           10
#define INITIAL_PKT_LENGTH  10

unsigned fail(int x)
{

    printstr("\nXCORE: ### FAIL ******");
    switch(x)
    {
        case FAIL_RX_DATAERROR:
		    printstr("XCORE RX Data Error\n");
            break;

        case FAIL_RX_LENERROR:
		    printstr("XCORE RX Length Error\n");
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

        //asm("ld8u %0, %1[%2]":"=r"(x):"r"(g_txDataCheck),"r"(epNum));
       // read_byte_via_xc_ptr_indexed(x, p_txDataCheck, epNum);

        //buffer[i] = x;
        //x++;
        //asm("st8 %0, %1[%2]"::"r"(x),"r"(g_txDataCheck),"r"(epNum));
        //write_byte_via_xc_ptr_indexed(p_txDataCheck,epNum,x);
    }

    XUD_SetBuffer(ep, buffer, length);
}

#pragma unsafe arrays
int TestEp_Bulk_Tx(chanend c_in1, int epNum1)
{
    XUD_ep ep_in1  = XUD_InitEp(c_in1);
    
    unsigned char buffer[PKT_COUNT][1024];

    int counter = 0;
    int length = INITIAL_PKT_LENGTH;

    for(int i = 0; i< PKT_COUNT; i++)
    {
        for(int j = 0; j < length; j++)
        {
            buffer[i][j] = counter++;
        }
        length++;
    }

    length = INITIAL_PKT_LENGTH;

#pragma loop unroll
    for(int i = 0; i < PKT_COUNT; i++)
    {
        XUD_SetBuffer(ep_in1, buffer[i], length++);
    }

    exit(0);

}



#define USB_CORE 0
int main()
{
    chan c_ep_out[XUD_EP_COUNT_OUT], c_ep_in[XUD_EP_COUNT_IN];
    chan c_sync;
    chan c_sync_iso;

    par
    {
        
        XUD_Manager( c_ep_out, XUD_EP_COUNT_OUT, c_ep_in, XUD_EP_COUNT_IN,
                                null, epTypeTableOut, epTypeTableIn,
                                null, null, -1, XUD_SPEED_HS, XUD_PWR_BUS);

        TestEp_Bulk_Tx(c_ep_in[3], 3);
    }

    return 0;
}
