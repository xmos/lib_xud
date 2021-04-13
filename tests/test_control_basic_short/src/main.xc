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
//#include "test.h"
#include "xc_ptr.h"

//#error

#define XUD_EP_COUNT_OUT   5
#define XUD_EP_COUNT_IN    5

//extern xc_ptr char_array_to_xc_ptr(const unsigned char a[]);

/* Endpoint type tables */
XUD_EpType epTypeTableOut[XUD_EP_COUNT_OUT] = {XUD_EPTYPE_CTL,
                                                XUD_EPTYPE_BUL,
                                                XUD_EPTYPE_ISO,
                                                XUD_EPTYPE_BUL,
                                                 XUD_EPTYPE_BUL};
XUD_EpType epTypeTableIn[XUD_EP_COUNT_IN] =   {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL, XUD_EPTYPE_ISO, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL};

/* USB Port declarations */
//on stdcore[0]: out port p_usb_rst = XS1_PORT_1A;
//on stdcore[0]: clock    clk       = XS1_CLKBLK_3;

//on stdcore[0] : out port p_test = XS1_PORT_1I;

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

        //asm("ld8u %0, %1[%2]":"=r"(x):"r"(g_txDataCheck),"r"(epNum));
       // read_byte_via_xc_ptr_indexed(x, p_txDataCheck, epNum);

        //buffer[i] = x;
        //x++;
        //asm("st8 %0, %1[%2]"::"r"(x),"r"(g_txDataCheck),"r"(epNum));
        //write_byte_via_xc_ptr_indexed(p_txDataCheck,epNum,x);
    }

    XUD_SetBuffer(ep, buffer, length);
}





//xc_ptr p_rxDataCheck;
//xc_ptr p_txDataCheck;
//xc_ptr p_txLength;

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

    //while(1)
    {
        /* Wait for Setup data */
        res = XUD_GetControlBuffer(c_ep0_out, buffer, slength);

        if(slength != 8)
        {
            printintln(length);
            fail(FAIL_RX_DATAERROR);
        }

        if(RxDataCheck(buffer, slength, epNum))
        {
            fail(FAIL_RX_DATAERROR);
        }

        res = XUD_GetBuffer(c_ep0_out, buffer, slength);

        if(RxDataCheck(buffer, length, epNum))
        {
            fail(FAIL_RX_DATAERROR);
        }


        /* Send 0 length back */
        SendTxPacket(c_ep0_in, 0, epNum);

#if 0
        res =  XUD_GetBuffer(c_ep0_out, buffer, length);
        if(RxDataCheck(buffer, length, epNum))
        {
            fail(FAIL_RX_DATAERROR);
        }

        res =  XUD_GetBuffer(c_ep0_out, buffer, length);
        if(RxDataCheck(buffer, length, epNum))
        {
            fail(FAIL_RX_DATAERROR);
        }


        /* Send 0 length back */
        SendTxPacket(c_ep0_in, 0, epNum);

         /* Wait for Setup data */
        res = XUD_GetSetupBuffer(c_ep0_out, buffer, slength);

        if(slength != 8)
        {
            printintln(length);
            fail(FAIL_RX_DATAERROR);
        }

        if(RxDataCheck(buffer, slength, epNum))
        {
            fail(FAIL_RX_DATAERROR);
        }


        SendTxPacket(c_ep0_in, length, epNum);
        SendTxPacket(c_ep0_in, length, epNum);
        SendTxPacket(c_ep0_in, length, epNum);

        res =  XUD_GetBuffer(c_ep0_out, buffer, length);
        if(length != 0)
        {
            fail(FAIL_RX_DATAERROR);
        }
#endif
        exit(0);


    }
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

        TestEp_Control(c_ep_out[0], c_ep_in[0], 0);
    }

    return 0;
}
