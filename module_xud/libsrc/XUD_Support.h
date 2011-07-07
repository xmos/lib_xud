/** @file      XUD_Support.h 
  * @brief     Various  support functions used in XUD 
  * @author    Ross Owen, XMOS Limited
  * @version   0v9
 */

#ifndef _XUD_SUPPORT_H_
#define _XUD_SUPPORT_H_ 1

/* Typedefs for resources */
typedef unsigned XUD_lock;
typedef unsigned XUD_chan;

/* Functions for using locks */
XUD_lock XUD_Sup_GetLock();
void XUD_Sup_ClaimLock(XUD_lock l);
void XUD_Sup_FreeLock(XUD_lock l);
void XUD_Sup_FreerLock(XUD_lock l);

// Delay execution (Uses timer)
void XUD_Sup_Delay(unsigned x);

// Outpw
void XUD_Sup_Outpw8(out port p, unsigned x);
void XUD_Sup_Outpw16(out port p, unsigned x);
void XUD_Sup_Outpw24(out port p, unsigned x);

unsigned XUD_Sup_GetResourceId(chanend c);

// Inpw
unsigned XUD_Sup_Inpw24(in port p);
unsigned XUD_Sup_Inpw8( in port p);

// In
unsigned XUD_Sup_inuint(XUD_chan);
unsigned char XUD_Sup_inct(XUD_chan);
unsigned char XUD_Sup_int(XUD_chan);
unsigned char XUD_Sup_testct(XUD_chan);

unsigned XUD_Sup_clear(XUD_chan c) ;

// Out
void XUD_Sup_outuint(XUD_chan, unsigned x);
void XUD_Sup_outct(XUD_chan, unsigned char x);

void XUD_Sup_stop_streaming_master(XUD_chan);

unsigned GetArrayAddress(unsigned char a[]);

int XUD_Sup_getd(XUD_chan c);

#endif
