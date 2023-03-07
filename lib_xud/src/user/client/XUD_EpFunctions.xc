// Copyright 2011-2023 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
/** @file      XUD_EPFunctions.xc
  * @brief     Implementation of user API functions.  See xud.h for documentation.
  * @author    Ross Owen, XMOS Limited
  **/

#include <xs1.h>
#include "xud.h"
#include "XUD_USB_Defines.h"

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
    asm volatile("ldw %0, %1[2]":"=r"(c1):"r"(one));             // Load our chanend
    asm volatile ("outct res[%0], 1":: "r"(c1)); // Close channel to other side
    asm volatile ("chkct res[%0], 1":: "r"(c1)); // Close channel to this side
}

XUD_BusSpeed_t XUD_ResetEndpoint(XUD_ep one, XUD_ep &?two)
{
    int busStateCt;
    int busSpeed;

    unsigned c1, c2, tmp;

    /* Input rst control token */
    asm volatile("ldw %0, %1[2]":"=r"(c1):"r"(one));             // Load our chanend
    asm volatile ("inct %0, res[%1]": "=r"(busStateCt):"r"(c1)); // busStateCt = inct(one);

    if (!isnull(two))
    {
        asm volatile("ldw %0, %1[2]":"=r"(c2):"r"(two));
        asm volatile ("inct %0, res[%1]": "=r"(busStateCt):"r"(c2));
    }

    /* Clear ready flag (tidies small race where EP marked ready just after XUD clears ready due to reset */
    asm volatile("ldw %0, %1[0]":"=r"(tmp):"r"(one));           // Load address of ep in XUD rdy table
    asm volatile ("stw %0, %1[0]"::"r"(0), "r"(tmp));

    /* Clear resetting flag */
    asm volatile ("stw %0, %1[9]"::"r"(0), "r"(one));

    if(!isnull(two))
    {
        asm volatile("ldw %0, %1[0]":"=r"(tmp):"r"(two));       // Load address of ep in XUD rdy table
        asm volatile ("stw %0, %1[0]"::"r"(0), "r"(tmp));

         /* Reset reseting flag */
        asm volatile ("stw %0, %1[9]"::"r"(0), "r"(two));
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

