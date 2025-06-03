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

#ifndef TEST_EP_NUM
#define TEST_EP_NUM         1
#endif

#define PKT_LENGTH          10

#ifndef XUD_TEST_SPEED
#error XUD_TEST_SPEED not defined
#endif

/* Endpoint type tables */
XUD_EpType epTypeTableOut[XUD_EP_COUNT_OUT] = {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL | XUD_STATUS_ENABLE};
XUD_EpType epTypeTableIn[XUD_EP_COUNT_IN] =   {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL | XUD_STATUS_ENABLE};

#pragma unsafe arrays
testResult_t TestEpBusUpdate_Tx(XUD_ep ep_out0, XUD_ep ep_in, int epNum, int pktLen, t_runMode runMode)
{
    XUD_Result_t result;
    XUD_BusSpeed_t busSpeed;
    XUD_BusState_t busState;
    unsigned length;

    unsigned char bufferRx[1024];
    unsigned char bufferTx[1024];
    unsigned char bufferTxBad[1024];

    /* Prepare packet */
    for(int i = 0; i < pktLen; i++)
    {
        bufferTx[i] = i;
        bufferTxBad[i] = 0xBA;
    }

    /* At this point (due to test packet sequencing and code ordering) that XUD has already sent
     * a bus reset notification. This packet should never make it to the host */
    result = XUD_SetBuffer(ep_in, bufferTxBad, pktLen);

    if(result != XUD_RES_UPDATE)
        return FAIL_UNEXPECTED_STATUS;

    /* Since device has received a reset, don't expect the old buffer we set above to actually
     * be transmitted. The EP should now be NAKing */

    /* Sync with the host via EP0 so we know we can now get the bus status update and set some fresh
     * data */
    result = XUD_GetBuffer(ep_out0, bufferRx, length);

    if(result != XUD_RES_OKAY)
        return FAIL_UNEXPECTED_STATUS;

    busState = XUD_GetBusState(ep_in, null);
    busSpeed = XUD_ResetEndpoint(ep_in, null);

    if(busState != XUD_BUS_RESET)
        return FAIL_UNEXPECTED_BUS_STATE;

    if(busSpeed != XUD_TEST_SPEED)
        return FAIL_BAD_BUS_SPEED;

    /* Mark EP ready with a fresh new buffer */
    result = XUD_SetBuffer(ep_in, bufferTx, pktLen);

    if(result != XUD_RES_OKAY)
        return FAIL_UNEXPECTED_STATUS;

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

testResult_t TestEpBusUpdate_Rx(XUD_ep ep_out0, XUD_ep ep_out1, int epNum, int expectedLength)
{
    XUD_Result_t result;
    XUD_BusState_t busState;
    XUD_BusSpeed_t busSpeed = XUD_TEST_SPEED;

    /* Buffer for packet data and lengths */
    unsigned char buffer[1024];
    unsigned length;

    /* Get packet on EP 0 such that we know host has end reset */
    result = XUD_GetBuffer(ep_out0, buffer, length);

    if(result != XUD_RES_OKAY)
        return FAIL_UNEXPECTED_STATUS;

    /* Expect reset notification - reset should of ready happened whilst the test EP wasn't marked
     * ready */
    result = XUD_GetBuffer(ep_out1, buffer, length);

    if(result != XUD_RES_UPDATE)
        return FAIL_UNEXPECTED_STATUS;

    busState = XUD_GetBusState(ep_out1, null);
    busSpeed = XUD_ResetEndpoint(ep_out1, null);

    if(busState != XUD_BUS_RESET)
        return FAIL_UNEXPECTED_BUS_STATE;

    if(busSpeed != XUD_TEST_SPEED)
        return FAIL_BAD_BUS_SPEED;

    /* Expect a packet */
    result = XUD_GetBuffer(ep_out1, buffer, length);

    if(result != XUD_RES_OKAY)
        return FAIL_UNEXPECTED_STATUS;

    unsafe
    {
        unsigned fail = RxDataCheck(buffer, length, epNum, expectedLength);
        if (fail)
            return fail;
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
    chan c_sync;

    testResult_t failRx;
    testResult_t failTx;

    par
    {
        {
            XUD_Main(c_ep_out, XUD_EP_COUNT_OUT, c_ep_in, XUD_EP_COUNT_IN,
                null, epTypeTableOut, epTypeTableIn, XUD_TEST_SPEED, XUD_PWR_BUS);

            /* Sync when XUD returns */
            c_sync <: (int) 0;
        }

        {
            set_core_fast_mode_on();
            XUD_ep ep_out0 = XUD_InitEp(c_ep_out[0]);
            XUD_ep ep_out1 = XUD_InitEp(c_ep_out[TEST_EP_NUM]);
            XUD_ep ep_in0 = XUD_InitEp(c_ep_in[0]);
            XUD_ep ep_in1 = XUD_InitEp(c_ep_in[TEST_EP_NUM]);

            failRx = TestEpBusUpdate_Rx(ep_out0, ep_out1, TEST_EP_NUM, PKT_LENGTH);

            failTx = TestEpBusUpdate_Tx(ep_out0, ep_in1, TEST_EP_NUM, PKT_LENGTH, RUNMODE_DIE);

            /* Tell XUD to close down */
            XUD_Kill(ep_in0);

            /* Accept the kill notifications from XUD */
            XUD_GetBusState(ep_out0, ep_out1);
            XUD_GetBusState(ep_in0, ep_in1);
            XUD_CloseEndpoint(ep_out0);
            XUD_CloseEndpoint(ep_out1);
            XUD_CloseEndpoint(ep_in0);
            XUD_CloseEndpoint(ep_in1);

            /* Wait for XUD return so we know it's safe to exit */
            int sync;
            c_sync :> sync;

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
