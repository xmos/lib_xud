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
#include "test.h"

#define XUD_EP_COUNT_OUT   3
#define XUD_EP_COUNT_IN    3

/* TODO.. PID TOGGLING CHECKS */


/* Endpoint type tables */
XUD_EpType epTypeTableOut[XUD_EP_COUNT_OUT] = {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL, XUD_EPTYPE_ISO};
XUD_EpType epTypeTableIn[XUD_EP_COUNT_IN] =   {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL, XUD_EPTYPE_ISO};

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
    
    XUD_ep c_ep1 = XUD_Init_Ep(chan_ep1);
   
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

    printstr("\nXCORE: ***** FAIL ******");
    switch(x)
    {
        case FAIL_RX_DATAERROR:
		    printstr("RX Data Error\n");

            break;

    }

    exit(1);	
}

unsigned char g_rxDataCheck[3] = {1, 1, 1};
unsigned char g_txDataCheck[3] = {1, 1, 1};
unsigned g_txLength[3] = {0,0,0};

unsigned char g_workingBuffer[3][1024];


/* Returns 0 for non-error */
#pragma unsafe arrays
int RxDataCheck(unsigned char b[], int l, int epNum)
{
    int fail = 0;
    unsigned char x;

    for (int i = 0; i < l; i++)
    {
        if(b[i] != g_rxDataCheck[epNum])
        {
            return 1;
        }

        asm("ld8u %0, %1[%2]":"=r"(x):"r"(g_rxDataCheck),"r"(epNum)); 
        x++;     
        asm("st8 %0, %1[%2]"::"r"(x),"r"(g_rxDataCheck),"r"(epNum));
       // g_rxDataCheck[epNum]++;
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

    XUD_ep ep = XUD_Init_Ep(chan_ep);
    
    int one = 1;

    while(1)
    {
        	
        length = XUD_GetBuffer(ep, buffer);

	    /* Check length */
	    if(length != buffer[0])
	    {
	        //	/fail();
	    }

        /* Update tx length to rx length */
        asm("stw   %0, dp[g_txLength]":: "r" (length));
        //g_txLength[epNum] = length;

        if(RxDataCheck(buffer, length, epNum))
        {
            fail(FAIL_RX_DATAERROR);
        }


	    /* Perform transform on buffer - pretty simple for the mo.. */
	    //for(int i = 0; i < length; i++)
	    //{
		  //  g_workingBuffer[epNum][i] += buffer[i];
	   // }

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
        asm("ld8u %0, %1[%2]":"=r"(x):"r"(g_txDataCheck),"r"(epNum)); 
        buffer[i] = x;
        x++;     
        asm("st8 %0, %1[%2]"::"r"(x),"r"(g_txDataCheck),"r"(epNum));
        //buffer[i] = g_txDataCheck[epNum]++;
    }

    XUD_SetBuffer(ep, buffer, length);
}


void TestEp_in(chanend chan_ep, chanend c_sync, int epNum) 
{
    unsigned char buffer[1024];
    int y;
    unsigned length;

    XUD_ep ep = XUD_Init_Ep(chan_ep);

    c_sync :> y;
    asm("ldw   %0, dp[g_txLength]" : "=r" (length) :);
    SendTxPacket(ep, length, epNum);

    while(1)
    {
        //c_sync :> y;
        asm("ldw   %0, dp[g_txLength]" : "=r" (length) :);
        SendTxPacket(ep, length, epNum);
    }

}

#define USB_CORE 0
int main() 
{
    chan c_ep_out[XUD_EP_COUNT_OUT], c_ep_in[XUD_EP_COUNT_IN];
    chan c_sync;
    chan c_sync_iso;

    par 
    {
        
        on stdcore[USB_CORE]: XUD_Manager( c_ep_out, XUD_EP_COUNT_OUT, c_ep_in, XUD_EP_COUNT_IN,
                                null, epTypeTableOut, epTypeTableIn,
                                p_usb_rst, clk, -1, XUD_SPEED_HS, null); 
        
#if (TEST_CRC_BAD) || (TEST_ACK)
        on stdcore[USB_CORE]: TestEp_out(c_ep_out[1], c_sync, 1);
        on stdcore[USB_CORE]: TestEp_in(c_ep_in[1], c_sync, 1);
        on stdcore[USB_CORE]: TestEp_out(c_ep_out[2], c_sync_iso, 2);
        on stdcore[USB_CORE]: TestEp_in(c_ep_in[2], c_sync_iso, 2);
#endif
    }

    return 0;
}
