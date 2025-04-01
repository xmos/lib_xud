// Copyright 2016-2025 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include <xs1.h>
#include <print.h>
#include <stdio.h>
#include "xud.h"
#include "platform.h"
#include "xud_shared.h"

#define XUD_EP_COUNT_OUT    2
#define XUD_EP_COUNT_IN     2

#ifndef PKT_LENGTH_START
#define PKT_LENGTH_START    10
#endif

#ifndef PKT_LENGTH_END
#define PKT_LENGTH_END      11
#endif

#ifndef TEST_EP_NUM
#define TEST_EP_NUM         1
#endif

#ifndef XUD_TEST_SPEED
#error XUD_TEST_SPEED not defined
#endif

/* Endpoint type tables */
XUD_EpType epTypeTableOut[XUD_EP_COUNT_OUT] = {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL | XUD_STATUS_ENABLE};
XUD_EpType epTypeTableIn[XUD_EP_COUNT_IN] =   {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL | XUD_STATUS_ENABLE};

#pragma unsafe arrays
testResult_t TestEpBusUpdate_Tx(chanend c_in, int epNum, unsigned start, unsigned end, t_runMode runMode)
{
    XUD_Result_t result;
    XUD_BusSpeed_t busSpeed;
    XUD_ep ep_in  = XUD_InitEp(c_in);
    int i = 0;

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
    do
    {
        result = XUD_SetBuffer(ep_in, buffer[i], length);

        if(result == XUD_RES_UPDATE)
        {
            XUD_BusState_t busState = XUD_GetBusState(ep_in, null);

            if(busState != XUD_BUS_RESET)
                return FAIL_UNEXPECTED_STATUS;

            busSpeed = XUD_ResetEndpoint(ep_in, null);

            if(busSpeed != XUD_TEST_SPEED)
                return FAIL_BAD_BUS_SPEED;

            if(i != 0) // Only expect reset on attach/first packet
                return FAIL_UNEXPECTED_RESET;
        }
        else
        {
            assert(result == XUD_RES_OKAY);
            i++;
            length++;
        }
    }
    while(i <= (end - start));

    /* Allow a little time for Tx data to make it's way of the port - important for FS tests */
    {
        timer t;
        unsigned time;
        t :> time;
        t when timerafter(time + 500) :> int _;
    }

    if(runMode != RUNMODE_DIE)
        while(1);

    return 0;
}

testResult_t TestEpBusUpdate_Rx(chanend c_out, int epNum, int start, int end)
{
    unsigned int length[MAX_PKT_COUNT];
    XUD_Result_t result;
    XUD_BusSpeed_t busSpeed = XUD_TEST_SPEED;
    int i = 0;

    XUD_ep ep_out = XUD_InitEp(c_out);

    /* Buffer for Setup data */
    unsigned char buffer[MAX_PKT_COUNT][1024];

    set_core_fast_mode_on();

    /* Receive a bunch of packets quickly, then check them */
#pragma loop unroll
    do
    {
        result = XUD_GetBuffer(ep_out, buffer[i], length[i]);

        if(result == XUD_RES_UPDATE)
        {
            XUD_BusState_t busState = XUD_GetBusState(ep_out, null);

            if(busState != XUD_BUS_RESET)
                return FAIL_UNEXPECTED_STATUS;

            busSpeed = XUD_ResetEndpoint(ep_out, null);

            if(busSpeed != XUD_TEST_SPEED)
                return FAIL_BAD_BUS_SPEED;

            if(i != 0) // Only expect reset on attach/first packet
               return FAIL_UNEXPECTED_RESET;
        }
        else
        {
            assert(result == XUD_RES_OKAY);
            i++;
        }
    }
    while(i <= (end-start));

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

#ifdef XUD_SIM_RTL
int testmain()
#else
int main()
#endif
{
    chan c_ep_out[XUD_EP_COUNT_OUT], c_ep_in[XUD_EP_COUNT_IN];

    testResult_t failRx;
    testResult_t failTx;
    testResult_t * unsafe failRxPtr;

    unsafe
    {
        failRxPtr = &failRx;
    }
    par
    {
        XUD_Main(c_ep_out, XUD_EP_COUNT_OUT, c_ep_in, XUD_EP_COUNT_IN,
                null, epTypeTableOut, epTypeTableIn, XUD_TEST_SPEED, XUD_PWR_BUS);

        unsafe
        {
            *failRxPtr = TestEpBusUpdate_Rx(c_ep_out[TEST_EP_NUM], TEST_EP_NUM, PKT_LENGTH_START, PKT_LENGTH_END);
        }

        {
            testResult_t failRx;
            failTx = TestEpBusUpdate_Tx(c_ep_in[TEST_EP_NUM], TEST_EP_NUM, PKT_LENGTH_START, PKT_LENGTH_END, RUNMODE_DIE);

            XUD_ep ep0 = XUD_InitEp(c_ep_out[0]);
            XUD_Kill(ep0);

            unsafe
            {
                failRx = *failRxPtr;
            }

            if(failTx)
                TerminateFail(failTx);
            else if(failRx)
                TerminateFail(failRx);
            else
                TerminatePass(0);
        }
    }

    return 0;
}
