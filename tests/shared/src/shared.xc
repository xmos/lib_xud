// Copyright 2016-2022 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include <xs1.h>
#include <print.h>
#include "xud_shared.h"

unsigned char g_rxDataCheck_[16] = {0};
unsigned char g_txDataCheck_[16] = {0};
unsigned g_txLength[16]          = {0};

unsafe
{
    unsigned char volatile * unsafe g_rxDataCheck = g_rxDataCheck_;
    unsigned char volatile * unsafe g_txDataCheck = g_txDataCheck_;
}

#ifdef XUD_SIM_XSIM
/* Alternatives to the RTL sim testbench functions */
void TerminateFail(int failReason)
{
    switch(failReason)
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
    exit(failReason);
}
void TerminatePass(int x)
{
    exit(0);
}
#endif

#pragma unsafe arrays
void GenTxPacketBuffer(unsigned char buffer[], int length, int epNum)
{
    for (int i = 0; i < length; i++)
    unsafe
    {
        buffer[i] = g_txDataCheck[epNum]++;
    }
    return;
}

#pragma unsafe arrays
XUD_Result_t SendTxPacket(XUD_ep ep, int length, int epNum)
{
    unsigned char buffer[1024];

    GenTxPacketBuffer(buffer, length, epNum);

    return XUD_SetBuffer(ep, buffer, length);
}

#pragma unsafe arrays
int TestEp_Tx(chanend c_in, int epNum1, unsigned start, unsigned end, t_runMode runMode)
{
    XUD_ep ep_in  = XUD_InitEp(c_in);

    unsigned char buffer[MAX_PKT_COUNT][1024];

    int counter = 0;
    int length = start;

    set_core_fast_mode_on();

    /* Prepare packets */
    for(int i = 0; i <= (end - start); i++)
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

    /* Allow a little time for Tx data to make it's way of the port - important for FS tests */
    {
        timer t;
        unsigned time;
        t :> time;
        t when timerafter(time + 500) :> int _;
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
    {
        printstr("#### Unexpected length on EP: ");
        printint(epNum);
        printstr(". Got: ");
        printint(l);
        printstr(" Expected: ");
        printintln(expectedLength);
        return FAIL_RX_LENERROR;
    }

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

    set_core_fast_mode_on();

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

/* Loopback packets forever */
#pragma unsafe arrays
int TestEp_Loopback(chanend c_out1, chanend c_in1, t_runMode runMode)
{
    unsigned int length;
    XUD_Result_t res;

    set_core_fast_mode_on();

    XUD_ep ep_out1 = XUD_InitEp(c_out1);
    XUD_ep ep_in1  = XUD_InitEp(c_in1);

    /* Buffer for Setup data */
    unsigned char buffer[1024];

    while(1)
    {
        XUD_GetBuffer(ep_out1, buffer, length);
        XUD_SetBuffer(ep_in1, buffer, length);

        /* Loop back once and return */
        if(runMode == RUNMODE_DIE)
            break;

        /* Partial un-roll */
        XUD_GetBuffer(ep_out1, buffer, length);
        XUD_SetBuffer(ep_in1, buffer, length);
    }
}

#ifndef TEST_DTHREADS
#error TEST_DTHREADS not defined
#define TEST_DTHREADS (0)
#endif

#if (TEST_DTHREADS > 6)
#error TEST_DTHREADS too high
#endif

size_t g_dummyThreadCount = TEST_DTHREADS;

void dummyThread()
{
    unsigned x = 0;
    set_core_fast_mode_on();

    while(g_dummyThreadCount)
    {
        x++;
    }
}

void dummyThreads()
{
#if (TEST_DTHREADS > 0)
    par(size_t i = 0; i < TEST_DTHREADS; i++)
    {
        dummyThread();
    }
#endif
}

