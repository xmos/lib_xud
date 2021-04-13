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
int RxDataCheck(unsigned char b[], int l, int epNum)
{
    int fail = 0;
    unsigned char x;

    for (int i = 0; i < l; i++)
    {
        unsigned char y;
        //read_byte_via_xc_ptr_indexed(y, p_rxDataCheck, epNum);
        if(b[i] != g_rxDataCheck[epNum])
        {
            printstr("#### Mismatch on EP: ");
            printint(epNum); 
            printstr(". Got:");
            printhex(b[i]);
            printstr(" Expected:");
            printhexln(g_rxDataCheck[epNum]);
            //printintln(l); // Packet length
            return 1;
        }

        g_rxDataCheck[epNum]++;
        //read_byte_via_xc_ptr_indexed(x, p_rxDataCheck, epNum);
        //x++;
        //write_byte_via_xc_ptr_indexed(p_rxDataCheck,epNum,x);
    }

    return 0;
}

int TestEp_Bulk(chanend c_out1, chanend c_in1, int epNum1, chanend c_out2, chanend c_in2, int epNum2)
{
    unsigned int length;
    XUD_Result_t res;

    XUD_ep ep_out1 = XUD_InitEp(c_out1);
    XUD_ep ep_out2 = XUD_InitEp(c_out2);
    XUD_ep ep_in1  = XUD_InitEp(c_in1);
    XUD_ep ep_in2 = XUD_InitEp(c_in2);

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

        TestEp_Bulk(c_ep_out[1], c_ep_in[1], 1, c_ep_out[2], c_ep_in[2], 2);
    }

    return 0;
}
