// Copyright 2022 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include "xud_shared.h"

#define EP_COUNT_OUT       (7)
#define EP_COUNT_IN        (7)

#define PACKET_LEN_START   (10)
#define PACKET_LEN_END     (19)

/* Check for clashes with TEST_EP and traffic EP */
#if TEST_EP_NUM == 4
#error TEST_EP_NUM clashes with traffic EP
#endif

#if TEST_EP_NUM == 5
#error TEST_EP_NUM clashes with traffic EP
#endif

#if TEST_EP_NUM == 6
#error TEST_EP_NUM clashes with traffic EP
#endif

#define TEST_EP_COUNT      (3)

/* Endpoint type tables */
XUD_EpType epTypeTableOut[EP_COUNT_OUT] = {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL};
XUD_EpType epTypeTableIn[EP_COUNT_IN] =   {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL, XUD_EPTYPE_BUL};

unsigned test_func(chanend c_ep_out[EP_COUNT_OUT], chanend c_ep_in[EP_COUNT_IN])
{
    unsigned char buffer0[MAX_PKT_COUNT][512];
    unsigned char buffer1[MAX_PKT_COUNT][512];
    unsigned char buffer2[MAX_PKT_COUNT][512];
    XUD_Result_t result;
    unsigned length;
    unsigned exit = 0;
    unsigned pktLength[TEST_EP_COUNT];
    unsigned bufferIndex[TEST_EP_COUNT];

    for(size_t i = 0; i< TEST_EP_COUNT; i++)
    {
        pktLength[i] = PACKET_LEN_START;
        bufferIndex[i] = 0;
    }

    XUD_ep ep_out0 = XUD_InitEp(c_ep_out[TEST_EP_NUM]);
    XUD_SetReady_Out(ep_out0, buffer0[bufferIndex[0]++]);

    XUD_ep ep_out1 = XUD_InitEp(c_ep_out[TEST_EP_NUM+1]);
    XUD_SetReady_Out(ep_out1, buffer1[bufferIndex[1]++]);

    XUD_ep ep_out2 = XUD_InitEp(c_ep_out[TEST_EP_NUM+2]);
    XUD_SetReady_Out(ep_out2, buffer2[bufferIndex[2]++]);

    while(!exit)
    {
        select
        {
            case XUD_GetData_Select(c_ep_out[TEST_EP_NUM], ep_out0, length, result):

                if (length != pktLength[0]++)
                    return 1;

                XUD_SetReady_Out(ep_out0, buffer0[bufferIndex[0]++]);
                break;

            case XUD_GetData_Select(c_ep_out[TEST_EP_NUM+1], ep_out1, length, result):

                if (length != pktLength[1]++)
                    return 1;

                XUD_SetReady_Out(ep_out1, buffer1[bufferIndex[1]++]);
                break;

            case XUD_GetData_Select(c_ep_out[TEST_EP_NUM+2], ep_out2, length, result):

                if (length != pktLength[2]++)
                    return 1;

                XUD_SetReady_Out(ep_out2, buffer2[bufferIndex[2]++]);
                break;
        }

        exit = 1;
        for (size_t i = 0; i < 3; i++)
        {
            if(pktLength[i] <= PACKET_LEN_END)
            {
                exit = 0;
            }
        }
    }

    length = PKT_LEN_START;
    unsigned char counter = 0;

#pragma unsafe arrays
    for(size_t i = 0; i < (PACKET_LEN_END - PACKET_LEN_START); i++)
    {
        for(size_t j = 0; j < length; j++)
        {
            if(buffer0[i][j] != counter)
            {
                printstr("Mismatch:");
                printhexln(buffer0[i][j]);
                return 1;
            }
            if(buffer1[i][j] != counter)
            {
                printstr("Mismatch:");
                printhexln(buffer1[i][j]);
                return 1;
            }
            if(buffer2[i][j] != counter)
            {
                printstr("Mismatch:");
                printhexln(buffer2[i][j]);
                return 1;
            }
            counter++;
        }
        length++;
    }

    return 0;
}

#include "test_main.xc"
