// Copyright (c) 2011-2018, XMOS Ltd, All rights reserved
/** XUD_UIFM_RegAccess.S
  * @brief     Functions for UIFM register read/write
  * @author    Ross Owen, XMOS Limited
  */

#include <xud.h>

#include <xs1.h>

#ifndef GLX
#ifndef XS1_PS_XCORE_CTRL0
#define XS1_PS_XCORE_CTRL0 0x20b
#endif

.text
.globl XUD_UIFM_Enable, "f{ui}(ui)"
.type  XUD_UIFM_Enable, @function
.cc_top XUD_UIFM_Enable.function
.align    4
// void XUD_UIFM_Enable (unsigned mode);
XUD_UIFM_Enable:
  ldc       r1, XS1_PS_XCORE_CTRL0
  set       ps[r1], r0

  // Sanity check, read back and check
  //get	    r1, ps[r1]
  //eq        r1, r0, r1
  //ecallf    r1
  retsp 0

.size XUD_UIFM_Enable, .-XUD_UIFM_Enable
.cc_bottom XUD_UIFM_Enable.function
.globl XUD_UIFM_Enable.nstackwords
.globl XUD_UIFM_Enable.maxchanends
.globl XUD_UIFM_Enable.maxtimers
.globl XUD_UIFM_Enable.maxcores
.set XUD_UIFM_Enable.nstackwords, 0
.set XUD_UIFM_Enable.maxchanends, 0
.set XUD_UIFM_Enable.maxtimers, 0
.set XUD_UIFM_Enable.maxcores, 1
.set XUD_UIFM_Enable.locnochandec, 1

#endif
