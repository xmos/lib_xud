// Copyright 2022 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include <xcore/select.h>
#include "test.h"
#include "shared.h"

#define PACKET_LEN_START   (10)
#define PACKET_LEN_END     (11)

#define PACKET_COUNT       (PACKET_LEN_END - PACKET_LEN_START + 2) 

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

#define TEST_EP_COUNT      (1)

int checkExit(unsigned pktLength[])
{
    int exit = 1;
    for (size_t i = 0; i < TEST_EP_COUNT; i++)
    {
        if(pktLength[i] <= (PACKET_LEN_END + 1))
        {
            exit = 0;
        }
    }
    return exit;
}

unsigned test_func(chanend c_ep_out[EP_COUNT_OUT], chanend c_ep_in[EP_COUNT_IN])
{
    unsigned char buffer[PACKET_COUNT][512];
    XUD_Result_t result;
    unsigned exit = 0;
    
    unsigned pktLength[TEST_EP_COUNT];
    unsigned bufferIndex[TEST_EP_COUNT];

    for(size_t i = 0; i< TEST_EP_COUNT; i++)
    {
        pktLength[i] = PACKET_LEN_START;
        bufferIndex[i] = 0;
    }

    unsigned char counter = 0;
    unsigned length = PACKET_LEN_START;

    /* Create the packets we are going to send */
    for(size_t i = 0; i < PACKET_COUNT; i++)
    {
        for(size_t j = 0; j < length; j++)
        {
            buffer[i][j] = counter++;
        }
        length++;
    } 

    XUD_ep ep_in0 = XUD_InitEp(c_ep_in[TEST_EP_NUM]);

    XUD_SetReady_In(ep_in0, buffer[bufferIndex[0]++], pktLength[0]++);
    
    while(1)
    {
        SELECT_RES(CASE_THEN(c_ep_out[TEST_EP_NUM], ep_a))
        {
            ep_a: 
                XUD_SetData_Select(c_ep_in[TEST_EP_NUM], ep_in0, &result);
                XUD_SetReady_In(ep_in0, buffer[bufferIndex[0]++], pktLength[0]++);
                exit = checkExit(pktLength);
                if (exit)
                    return 0;
                continue;
        }
    }

    // TODO do we need to do any checking?
    return 0;
}

