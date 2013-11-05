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

unsigned XUD_Sup_GetResourceId(chanend c);

// Channel comms - In
unsigned XUD_Sup_inuint(XUD_chan);
unsigned char XUD_Sup_inct(XUD_chan);
unsigned char XUD_Sup_int(XUD_chan);
unsigned char XUD_Sup_testct(XUD_chan);

// Channel comms - Out
void XUD_Sup_outuint(XUD_chan, unsigned x);
void XUD_Sup_outct(XUD_chan, unsigned char x);

#endif
