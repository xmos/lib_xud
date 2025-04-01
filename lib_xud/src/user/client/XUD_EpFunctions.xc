// Copyright 2011-2024 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
/** @file      XUD_EPFunctions.xc
  * @brief     Implementation of user API functions.  See xud.h for documentation.
  * @author    Ross Owen, XMOS Limited
  **/

#include <xs1.h>
#include "xud.h"
#include "XUD_USB_Defines.h"
#include "assert.h"

static inline int min(int x, int y)
{
    if (x < y)
        return x;
    return y;
}

void XUD_Kill(XUD_ep ep)
{
    XUD_SetTestMode(ep, 0);
}

#ifndef EP0_MAX_PACKET_SIZE
#define EP0_MAX_PACKET_SIZE (64)
#endif

/* TODO Should take ep max length as a param - currently hardcoded as 64 (#11384) */
XUD_Result_t XUD_DoGetRequest(XUD_ep ep_out, XUD_ep ep_in, unsigned char buffer[], unsigned length, unsigned requested)
{
    unsigned char tmpBuffer[1024];
    unsigned rxlength;
    unsigned sendLength = min(length, requested);
    XUD_Result_t result;

    if ((result = XUD_SetBuffer_EpMax(ep_in, buffer, sendLength, EP0_MAX_PACKET_SIZE)) != XUD_RES_OKAY)
    {
        return result;
    }

    /* USB 2.0 8.5.3.2: Send < 0 length packet when data-length % 64 is 0
     * Note, we also don't want to try and send 2 zero-length packets i.e. if sendLength = 0 */
    if ((requested > length) && ((length % EP0_MAX_PACKET_SIZE) == 0))
    {
        XUD_SetBuffer(ep_in, tmpBuffer, 0);
    }

    /* Status stage - this should return -1 for reset or 0 for 0 length status stage packet */
    return XUD_GetBuffer(ep_out, tmpBuffer, rxlength);
}

void XUD_CloseEndpoint(XUD_ep one)
{
    unsigned c1;

    /* Input rst control token */
    asm volatile("ldw %0, %1[2]":"=r"(c1):"r"(one));    // Load our chanend
    asm volatile ("outct res[%0], 1":: "r"(c1));        // Close channel to other side
    asm volatile ("chkct res[%0], 1":: "r"(c1));        // Close channel to this side
}

XUD_BusState_t XUD_GetBusState(XUD_ep one, XUD_ep &?two)
{
    unsigned busStateCt;
    unsigned c1, c2;

    /* Input bus update control token */
    asm volatile("ldw %0, %1[2]":"=r"(c1):"r"(one));             // Load our chanend
    asm volatile ("inct %0, res[%1]": "=r"(busStateCt):"r"(c1)); // busStateCt = inct(one);

    if (!isnull(two))
    {
        asm volatile("ldw %0, %1[2]":"=r"(c2):"r"(two));
        asm volatile ("inct %0, res[%1]": "=r"(busStateCt):"r"(c2));
    }

    switch(busStateCt)
    {
        case XUD_RESET_TOKEN:
            return XUD_BUS_RESET;
        case XUD_SUSPEND_TOKEN:
            return XUD_BUS_SUSPEND;
        case XUD_RESUME_TOKEN:
            return XUD_BUS_RESUME;
        default:
            assert(0);
            break;
    }
    return 0; // Unreachable
}

static void XUD_EPUpdateCommon(XUD_ep one, NULLABLE_REFERENCE_PARAM(XUD_ep, two))
{
    // Clear busUpdate flag and mark endpoint as not ready
    unsigned tmp;

    /* Clear ready flag (tidies small race where EP marked ready just after XUD clears ready due to reset */
    asm volatile("ldw %0, %1[0]":"=r"(tmp):"r"(one));           // Load address of ep in XUD rdy table
    asm volatile ("stw %0, %1[0]"::"r"(0), "r"(tmp));

    /* Clear busUpdate flag */
    asm volatile ("stw %0, %1[9]"::"r"(0), "r"(one));

    if(!isnull(two))
    {
        asm volatile("ldw %0, %1[0]":"=r"(tmp):"r"(two));       // Load address of ep in XUD rdy table
        asm volatile ("stw %0, %1[0]"::"r"(0), "r"(tmp));

         /* Reset busUpdate flag */
        asm volatile ("stw %0, %1[9]"::"r"(0), "r"(two));
    }
}

XUD_Result_t XUD_Ack(XUD_ep one, NULLABLE_REFERENCE_PARAM(XUD_ep, two))
{
    unsigned c1, c2;

    XUD_EPUpdateCommon(one, two);

    asm volatile("ldw %0, %1[2]":"=r"(c1):"r"(one));              // Load EP chanend

    if (!isnull(two))
    {
        asm volatile("ldw %0, %1[2]":"=r"(c2):"r"(two));          // Load EP chanend
    }


    asm volatile("ldw %0, %1[2]":"=r"(c1):"r"(one));              // Load EP chanend
    asm volatile ("outct res[%0], 9":: "r"(c1));                  // Send ACK. TODO remove magic number

    if (!isnull(two))
    {
        asm volatile("ldw %0, %1[2]":"=r"(c2):"r"(two));          // Load EP chanend
        asm volatile ("outct res[%0], 9":: "r"(c2));              // Send ACK. TODO remove magic number
    }

    return XUD_RES_OKAY;
}


XUD_BusSpeed_t XUD_ResetEndpoint(XUD_ep one, XUD_ep &?two)
{
    int busSpeed;

    unsigned c1, c2, tmp;

    XUD_EPUpdateCommon(one, two);

    asm volatile("ldw %0, %1[2]":"=r"(c1):"r"(one));              // Load EP chanend

    if (!isnull(two))
    {
        asm volatile("ldw %0, %1[2]":"=r"(c2):"r"(two));          // Load EP chanend
    }

    asm volatile("testct %0, res[%1]" : "=r"(tmp) : "r"(c1));

    if(tmp)
    {
        printstr("CT\n");
    }

    /* Expect a word with speed */
    asm volatile ("in %0, res[%1]": "=r"(busSpeed):"r"(c1));

    if (!isnull(two))
    {
        asm volatile ("in %0, res[%1]": "=r"(busSpeed):"r"(c2));
    }
    return (XUD_BusSpeed_t) busSpeed;
}

XUD_ep XUD_InitEp(chanend c)
{
    XUD_ep ep = inuint(c);
    return ep;
}

