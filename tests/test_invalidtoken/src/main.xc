// Copyright 2016-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include <xs1.h>
#include <print.h>
#include <stdio.h>
#include "xud.h"
#include "platform.h"

#define EP_COUNT_OUT   (6)
#define EP_COUNT_IN    (6)

XUD_EpType epTypeTableOut[EP_COUNT_OUT] = {XUD_EPTYPE_CTL, 
                                            XUD_EPTYPE_BUL,
                                            XUD_EPTYPE_BUL,
                                            XUD_EPTYPE_BUL,
                                            XUD_EPTYPE_BUL,
                                            XUD_EPTYPE_BUL};

XUD_EpType epTypeTableIn[EP_COUNT_IN] =   {XUD_EPTYPE_CTL,
                                            XUD_EPTYPE_BUL,
                                            XUD_EPTYPE_BUL,
                                            XUD_EPTYPE_BUL,
                                            XUD_EPTYPE_BUL,
                                            XUD_EPTYPE_BUL};

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

unsigned char g_rxDataCheck[EP_COUNT_OUT] = {0};
unsigned char g_txDataCheck[EP_COUNT_IN] = {0};
unsigned g_txLength[EP_COUNT_IN] = {0};


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
    }

    return 0;
}

int TestEp_Bulk(chanend c_out, chanend c_in, int epNum, chanend c_out_0)
{
    unsigned int length;
    XUD_Result_t res;

    XUD_ep ep_out_0 = XUD_InitEp(c_out_0);
    XUD_ep ep_out = XUD_InitEp(c_out);
    XUD_ep ep_in  = XUD_InitEp(c_in);

    /* Buffer for Setup data */
    unsigned char buffer[1024];

    for(int i = 10; i <= 14; i++)
    {    
        XUD_GetBuffer(ep_out, buffer, length);

        if(length != i)
        {
            printintln(length);
            fail(FAIL_RX_LENERROR);
        }

        if(RxDataCheck(buffer, length, epNum))
        {
            fail(FAIL_RX_DATAERROR);
        }

    }

    XUD_Kill(ep_out_0);
    exit(0);
}

int main()
{
    chan c_ep_out[EP_COUNT_OUT], c_ep_in[EP_COUNT_IN];

    par
    {
        
        XUD_Main( c_ep_out, EP_COUNT_OUT, c_ep_in, EP_COUNT_IN,
                                null, epTypeTableOut, epTypeTableIn,
                                XUD_SPEED_HS, XUD_PWR_BUS);


        TestEp_Bulk(c_ep_out[TEST_EP_NUM], c_ep_in[TEST_EP_NUM], TEST_EP_NUM, c_ep_out[0]);
    }

    return 0;
}
