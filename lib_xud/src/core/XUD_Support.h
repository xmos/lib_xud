// Copyright 2011-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
/** @file      XUD_Support.h
  * @brief     Various  support functions used in XUD
  * @author    Ross Owen, XMOS Limited
 */

#ifndef _XUD_SUPPORT_H_
#define _XUD_SUPPORT_H_ 1

/* Typedefs for resources */
typedef unsigned XUD_lock;
typedef unsigned XUD_chan;

// Delay execution (Uses timer)
void XUD_Sup_Delay(unsigned x);

inline unsigned XUD_Sup_GetResourceId(chanend c)
{
    unsigned id;
    asm ("mov %0, %1" : "=r"(id) : "r"(c));
    return id;
}

// Channel comms - In
inline unsigned char XUD_Sup_inct(XUD_chan c)
{
    unsigned char x;
    asm volatile("inct %0, res[%1]" : "=r"(x) : "r"(c));
    return x;
}

inline unsigned char XUD_Sup_int(XUD_chan c)
{
    unsigned char x;
    asm volatile("int %0, res[%1]" : "=r"(x) : "r"(c));
    return x;
}

inline unsigned char XUD_Sup_testct(XUD_chan c)
{
    unsigned char x;
    asm volatile("testct %0, res[%1]" : "=r"(x) : "r"(c));
    return x;
}

// Channel comms - Out
inline void XUD_Sup_outuint(XUD_chan c, unsigned x)
{
    asm volatile("out res[%0], %1" : /* no outputs */ : "r"(c), "r"(x));
}

inline void XUD_Sup_outuchar(XUD_chan c, unsigned char x)
{
    asm volatile("outt res[%0], %1" : /* no outputs */ : "r"(c), "r"(x));
}

inline void XUD_Sup_outct(XUD_chan c, unsigned char x)
{
    asm volatile("outct res[%0], %1" : /* no outputs */ : "r"(c), "r"(x));
}

#endif
