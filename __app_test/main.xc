// Copyright (c) 2012-2018, XMOS Ltd, All rights reserved
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

#define XUD_EP_COUNT_OUT   5
#define XUD_EP_COUNT_IN    5

extern xc_ptr char_array_to_xc_ptr(const unsigned char a[]);

/* Endpoint type tables */
XUD_EpType epTypeTableOut[XUD_EP_COUNT_OUT] = {XUD_EPTYPE_CTL,
                                                XUD_EPTYPE_BUL,
                                                XUD_EPTYPE_ISO,
                                                XUD_EPTYPE_BUL,
                                                 XUD_EPTYPE_BUL};
XUD_EpType epTypeTableIn[XUD_EP_COUNT_IN] =   {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL, XUD_EPTYPE_ISO, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL};

/* USB Port declarations */
on stdcore[0]: out port p_usb_rst = XS1_PORT_1A;
on stdcore[0]: clock    clk       = XS1_CLKBLK_3;

on stdcore[0] : out port p_test = XS1_PORT_1I;

void Endpoint0( chanend c_ep0_out, chanend c_ep0_in, chanend ?c_usb_test);

char reportBuffer[] = {0, 0, 0, 0};



/*
 * This function responds to the HID requests - it draws a square using the mouse moving 40 pixels
 * in each direction in sequence every 100 requests.
 */
void hid(chanend chan_ep1)
{
    int counter = 0;
    int state = 0;

    XUD_ep c_ep1 = XUD_InitEp(chan_ep1);

    counter = 0;
    while(1)
    {
        counter++;
        if(counter == 400)
        {
            if(state == 0)
            {
                reportBuffer[1] = 40;
                reportBuffer[2] = 0;
                state+=1;
            }
            else if(state == 1)
            {
                reportBuffer[1] = 0;
                reportBuffer[2] = 40;
                state+=1;
            }
            else if(state == 2)
            {
                reportBuffer[1] = -40;
                reportBuffer[2] = 0;
                state+=1;
            }
            else if(state == 3)
            {
                reportBuffer[1] = 0;
                reportBuffer[2] = -40;
                state = 0;
            }
            counter = 0;
        }
        else
        {
            reportBuffer[1] = 0;
            reportBuffer[2] = 0;
        }

        if (XUD_SetBuffer(c_ep1, reportBuffer, 4) < 0)
        {
            XUD_ResetEndpoint(c_ep1, null);
        }
    }
}


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

const unsigned char g_rxDataCheck[5] = {1, 1, 1, 1, 1};
const unsigned char g_txDataCheck[5] = {1, 1, 1, 1, 1};
unsigned g_txLength[5] = {0,0,0,0,0};

xc_ptr p_rxDataCheck;
xc_ptr p_txDataCheck;
xc_ptr p_txLength;


#pragma unsafe arrays
int RxDataCheck(unsigned char b[], int l, int epNum)
{
    int fail = 0;
    unsigned char x;

   // printstr("##### RX DATA: \n");
    for (int i = 0; i < l; i++)
    {
        unsigned char y;
        read_byte_via_xc_ptr_indexed(y, p_rxDataCheck, epNum);
        if(b[i] != y)//g_rxDataCheck[epNum])
        {
            printstr("#### Mismatch\n");
            printhexln(b[i]);
            printhexln(g_rxDataCheck[epNum]);
            printhexln(epNum);
            printintln(l);
            return 1;
        }

        //g_rxDataCheck[epNum]++;
        read_byte_via_xc_ptr_indexed(x, p_rxDataCheck, epNum);
        x++;
        write_byte_via_xc_ptr_indexed(p_rxDataCheck,epNum,x);
    }

    return 0;
}

/* Out EP Should receive some data, perform some test process (crc or similar) to check okay */
/* Answers should be responded to in the IN ep */

#define TYPE_DATA 0
#define TYPE_CMD  1

#define TYPE_DATA               0
#define TYPE_CMD_SET_TX_LENGTH  1


/* Test packet format:
 * 0: 		Length
 * 1:       type (cmd/data)
 * 2:n-1:	Data
 */
#pragma unsafe arrays
void TestEp_out(chanend chan_ep, chanend c_sync, int epNum)
{
    unsigned char buffer[1024];
	int length;

	char x;

    XUD_ep ep = XUD_InitEp(chan_ep);

    int one = 1;

    while(1)
    {

        length = XUD_GetBuffer(ep, buffer);

        /* Update tx length to rx length */
        //asm("stw   %0, %1[%2]":: "r" (length), "r"(g_txLength), "r"(epNum));
        //g_txLength[epNum] = length;
        write_via_xc_ptr_indexed(p_txLength, epNum, x);

        if(RxDataCheck(buffer, length, epNum))
        {

            fail(FAIL_RX_DATAERROR);
        }


        if(one)
        {
            c_sync <: (int)1;
            one = 0;
        }
    }
}

#pragma unsafe arrays
void SendTxPacket(XUD_ep ep, int length, int epNum)
{
    unsigned char buffer[1024];
    unsigned char x;

    for (int i = 0; i < length; i++)
    {
        //buffer[i] = g_txDataCheck[epNum]++;

        //asm("ld8u %0, %1[%2]":"=r"(x):"r"(g_txDataCheck),"r"(epNum));
        read_byte_via_xc_ptr_indexed(x, p_txDataCheck, epNum);

        buffer[i] = x;
        x++;
        //asm("st8 %0, %1[%2]"::"r"(x),"r"(g_txDataCheck),"r"(epNum));
        write_byte_via_xc_ptr_indexed(p_txDataCheck,epNum,x);
    }

    XUD_SetBuffer(ep, buffer, length);
}


void TestEp_in(chanend chan_ep, chanend c_sync, int epNum)
{
    unsigned char buffer[1024];
    int y;
    unsigned length;

    XUD_ep ep = XUD_InitEp(chan_ep);

    c_sync :> y;
    //asm("ldw   %0, %1[%2]" : "=r" (length) :"r"(g_txLength), "r" (epNum));
    read_via_xc_ptr_indexed(length, p_txLength, epNum);

    //length = g_txLength[epNum];

    //printstr("FIRST: ");
    //printintln(length);

    SendTxPacket(ep, length, epNum);


    while(1)
    {
        read_via_xc_ptr_indexed(length, p_txLength, epNum);


        if((epNum == 2)&&(length!=0))
        {
        }
        SendTxPacket(ep, length, epNum);
    }

}

int TestEp_Control(chanend c_out, chanend c_in, int epNum)
{
    int slength;
    int length;

    XUD_ep c_ep0_out = XUD_InitEp(c_out);
    XUD_ep c_ep0_in  = XUD_InitEp(c_in);

    /* Buffer for Setup data */
    unsigned char buffer[120];

    while(1)
    {
        /* Wait for Setup data */
        slength = XUD_GetSetupBuffer(c_ep0_out, c_ep0_in, buffer);

        if(slength != 8)
        {
            printintln(length);
            fail(FAIL_RX_DATAERROR);
        }

        if(RxDataCheck(buffer, slength, epNum))
        {
            fail(FAIL_RX_DATAERROR);
        }

        length = XUD_GetBuffer(c_ep0_out, buffer);

        if(RxDataCheck(buffer, length, epNum))
        {
            fail(FAIL_RX_DATAERROR);
        }


        length = XUD_GetBuffer(c_ep0_out, buffer);
        if(RxDataCheck(buffer, length, epNum))
        {
            fail(FAIL_RX_DATAERROR);
        }

        length = XUD_GetBuffer(c_ep0_out, buffer);
        if(RxDataCheck(buffer, length, epNum))
        {
            fail(FAIL_RX_DATAERROR);
        }


        /* Send 0 length back */
        SendTxPacket(c_ep0_in, 0, epNum);

         /* Wait for Setup data */
        slength = XUD_GetSetupBuffer(c_ep0_out, c_ep0_in, buffer);

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

        length = XUD_GetBuffer(c_ep0_out, buffer);
        if(length != 0)
        {
            fail(FAIL_RX_DATAERROR);
        }




    }
}

void TestEp_select(chanend c_out1, chanend c_out2, chanend c_in1, chanend c_in2)
{
    XUD_ep ep_out1 = XUD_InitEp(c_out1);
    XUD_ep ep_out2  = XUD_InitEp(c_out2);
    XUD_ep ep_in1  = XUD_InitEp(c_in1);
    XUD_ep ep_in2  = XUD_InitEp(c_in2);

    unsigned char buffer1[1024];
    unsigned char buffer1_in[1024];
    unsigned char buffer2[1024];
    unsigned char buffer2_in[1024];
    int tmp;

#pragma unsafe arrays
    for(int i = 0; i < 10; i++)
    {
        int x;
        read_byte_via_xc_ptr_indexed(x, p_txDataCheck, 3);
        buffer1_in[i] = x;
        x++;
        write_byte_via_xc_ptr_indexed(p_txDataCheck,3,x);
    }

    XUD_SetReady_Out(ep_out1, buffer1);
    XUD_SetReady_Out(ep_out2, buffer2);
    XUD_SetReady_In(ep_in1, buffer1_in, 10);

    /* TODO - reset/CT etc */
    while(1)
    {
        select
        {
            case XUD_GetData_Select(c_out1, ep_out1, tmp):

                //doRxData
                if(RxDataCheck(buffer1, tmp, 3))
                {
                    fail(FAIL_RX_DATAERROR);
                }

                XUD_SetReady_Out(ep_out1, buffer1);

                break;

            case XUD_GetData_Select(c_out2, ep_out2, tmp):

                //doRxData
                if(RxDataCheck(buffer2, tmp, 4))
                {
                    fail(FAIL_RX_DATAERROR);
                }

                XUD_SetReady_Out(ep_out2, buffer2);

                break;

            case XUD_SetData_Select(c_in1, ep_in1, tmp):

                for (int i = 0; i < 10; i++)
                {
                    int x;
                    read_byte_via_xc_ptr_indexed(x, p_txDataCheck, 3);
                    buffer1_in[i] = x;
                    x++;
                    write_byte_via_xc_ptr_indexed(p_txDataCheck,3,x);
                }

                XUD_SetReady_In(ep_in1, buffer1_in, 10);



                break;

        }
    }
}


#define USB_CORE 0
int main()
{
    chan c_ep_out[XUD_EP_COUNT_OUT], c_ep_in[XUD_EP_COUNT_IN];
    chan c_sync;
    chan c_sync_iso;

    p_rxDataCheck = char_array_to_xc_ptr(g_rxDataCheck);
    p_txDataCheck = char_array_to_xc_ptr(g_txDataCheck);
    p_txLength = array_to_xc_ptr(g_txLength);

    par
    {

        XUD_Manager( c_ep_out, XUD_EP_COUNT_OUT, c_ep_in, XUD_EP_COUNT_IN,
                                null, epTypeTableOut, epTypeTableIn,
                                p_usb_rst, clk, -1, XUD_SPEED_HS, null);

         TestEp_Control(c_ep_out[0], c_ep_in[0], 0);

#if (TEST_CRC_BAD) || (TEST_ACK)
        TestEp_out(c_ep_out[1], c_sync, 1);
        TestEp_in(c_ep_in[1], c_sync, 1);
        //TestEp_out(c_ep_out[2], c_sync_iso, 2);
        //TestEp_in(c_ep_in[2], c_sync_iso, 2);
        TestEp_select(c_ep_out[3], c_ep_out[4], c_ep_in[3], c_ep_in[4]);
#endif
    }

    return 0;
}
