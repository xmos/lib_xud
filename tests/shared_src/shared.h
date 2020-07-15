// Copyright (c) 2016-2020, XMOS Ltd, All rights reserved
#include <xs1.h>
#include <print.h>
#include <stdio.h>
#include <platform.h>
#include "xud.h

unsigned char g_rxDataCheck_[16] = {0};
unsigned char g_txDataCheck_[16] = {0};
unsigned g_txLength[16]          = {0};

unsafe
{
    unsigned char volatile * unsafe g_rxDataCheck = g_rxDataCheck_;
    unsigned char volatile * unsafe g_txDataCheck = g_txDataCheck_;
}

void exit(int);

#define FAIL_RX_DATAERROR        1
#define FAIL_RX_LENERROR         2
#define FAIL_RX_EXPECTED_CTL     3   
#define FAIL_RX_BAD_RETURN_CODE  4
#define FAIL_RX_FRAMENUMBER      5

#ifdef XUD_SIM_XSIM
/* Alternatives to the RTL sim testbench functions */
void TerminateFail(unsigned x)
{
    switch(x)
    {
        case FAIL_RX_DATAERROR:
		    printstr("\nXCORE: ### FAIL ### : XCORE RX Data Error\n");
            break;

        case FAIL_RX_LENERROR:
		    printstr("\nXCORE: ### FAIL ### : XCORE RX Length Error\n");
            break;

        case FAIL_RX_EXPECTED_CTL:
            printstr("\nXCORE: ### FAIL ### : Expected a setup\n");
            break;
        
        case FAIL_RX_BAD_RETURN_CODE:
            printstr("\nXCORE: ### FAIL ### : Unexpected return code\n");
            break;

        case FAIL_RX_FRAMENUMBER:
            printstr("\nXCORE: ### FAIL ### : Received bad frame number\n");
            break;
    }
    exit(x);
}
void TerminatePass(unsigned x)
{
    exit(0);
}
#endif

#ifndef PKT_LEN_START
#define PKT_LEN_START  10
#endif

#ifndef PKT_LEN_END
#define PKT_LEN_END 21
#endif

#ifndef MAX_PKT_COUNT 
#define MAX_PKT_COUNT (10)
#endif


#define XUD_Manager XUD_Main

typedef enum t_runMode
{
    RUNMODE_LOOP,
    RUNMODE_DIE
} t_runMode;


#pragma unsafe arrays
XUD_Result_t SendTxPacket(XUD_ep ep, int length, int epNum)
{
    unsigned char buffer[1024];

    
    for (int i = 0; i < length; i++)
    unsafe {
        buffer[i] = g_txDataCheck[epNum]++;
    }

    return XUD_SetBuffer(ep, buffer, length);
}

#pragma unsafe arrays
int TestEp_Tx(chanend c_in, int epNum1, unsigned start, unsigned end, t_runMode runMode)
{
    XUD_ep ep_in  = XUD_InitEp(c_in);
    
    unsigned char buffer[MAX_PKT_COUNT][1024];

    int counter = 0;
    int length = start;

    /* Prepare packets */
    for(int i = 0; i <= (end-start); i++)
    {
        for(int j = 0; j < length; j++)
        {
            buffer[i][j] = counter++;
        }
        length++;
    }

#pragma loop unroll
    length = start;
    for(int i = 0; i <= (end - start); i++)
    {
        XUD_SetBuffer(ep_in, buffer[i], length++);
    }

    if(runMode == RUNMODE_DIE)
        return 0;
    else
        while(1);
}

#pragma unsafe arrays
int RxDataCheck(unsigned char b[], int l, int epNum, unsigned expectedLength)
{
    if (l != expectedLength)
        return 2;

    for (int i = 0; i < l; i++)
    {
        unsigned char y;
        
        unsafe
        {
            if(b[i] != g_rxDataCheck[epNum])
            {
#ifdef XUD_SIM_XSIM
                printstr("#### Mismatch on EP: ");
                printint(epNum); 
                printstr(". Got:");
                printhex(b[i]);
                printstr(" Expected:");
                printhex(g_rxDataCheck[epNum]);
                printstr(" Pkt len: ");
                printintln(l); // Packet length
#endif
                return 1;
            }

            g_rxDataCheck[epNum]++;
        }
    }

    return 0;
}

#pragma unsafe arrays
int TestEp_Rx(chanend c_out, int epNum, int start, int end)
{
    unsigned int length[MAX_PKT_COUNT];

    XUD_ep ep_out1 = XUD_InitEp(c_out);

    /* Buffer for Setup data */
    unsigned char buffer[MAX_PKT_COUNT][1024];

    /* Receive a bunch of packets quickly, then check them */
#pragma loop unroll
    for(int i = 0; i <= (end-start); i++)
    {
        XUD_GetBuffer(ep_out1, buffer[i], length[i]);
    }
#pragma loop unroll
    for(int i = 0; i <= (end-start); i++)
    {
        unsafe
        {
            unsigned expectedLength = start+i;
            unsigned fail = RxDataCheck(buffer[i], length[i], epNum, expectedLength);
            if (fail) 
                return fail;
                       
        }
    }

    return 0;
}

