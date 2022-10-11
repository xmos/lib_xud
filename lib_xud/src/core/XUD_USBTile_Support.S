// Copyright 2015-2022 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
/** XUD_USBTile_Support.S
  * @brief     Support functions for USB Tile use
  * @author    Ross Owen, XMOS Limited
  */

#ifdef __XS2A__
#include <xs2a_registers.h>
#endif
#if !defined(__XS2A__)
#include <xs1.h>
#endif
#include <XUD_AlignmentDefines.h>

.text
.globl XUD_EnableUsbPortMux, "f{ui}()"
.type  XUD_EnableUsbPortMux, @function
.cc_top XUD_EnableUsbPortMux.function
.align FUNCTION_ALIGNMENT
// void XUD_EnableUsbPortMux (unsigned mode);
XUD_EnableUsbPortMux:
.issue_mode single
  ENTSP_lu6 0
  ldc       r1, XS1_PS_XCORE_CTRL0
  get       r0, ps[r1]
  ldc       r2, 2
  or        r0, r0, r2
  set       ps[r1], r0

  //Sanity check, read back and check
  //get        r1, ps[r1]
  //eq         r1, r0, r1
  //ecallf     r1
  retsp     0

.size XUD_EnableUsbPortMux, .-XUD_EnableUsbPortMux
.cc_bottom XUD_EnableUsbPortMux.function
.globl XUD_EnableUsbPortMux.nstackwords
.globl XUD_EnableUsbPortMux.maxchanends
.globl XUD_EnableUsbPortMux.maxtimers
.globl XUD_EnableUsbPortMux.maxcores
.set XUD_EnableUsbPortMux.nstackwords, 0
.set XUD_EnableUsbPortMux.maxchanends, 0
.set XUD_EnableUsbPortMux.maxtimers, 0
.set XUD_EnableUsbPortMux.maxcores, 1
.set XUD_EnableUsbPortMux.locnochandec, 1

.globl XUD_DisableUsbPortMux, "f{ui}()"
.type  XUD_DisableUsbPortMux, @function
.cc_top XUD_DisableUsbPortMux.function
.align FUNCTION_ALIGNMENT
// void XUD_DisableUsbPortMux (unsigned mode);
XUD_DisableUsbPortMux:
  ldc       r1, XS1_PS_XCORE_CTRL0
  ldc       r0, 0
  set       ps[r1], r0

  //Sanity check, read back and check
  //get        r1, ps[r1]
  //eq         r1, r0, r1
  //ecallf     r1
  retsp     0

.size XUD_DisableUsbPortMux, .-XUD_DisableUsbPortMux
.cc_bottom XUD_DisableUsbPortMux.function
.globl XUD_DisableUsbPortMux.nstackwords
.globl XUD_DisableUsbPortMux.maxchanends
.globl XUD_DisableUsbPortMux.maxtimers
.globl XUD_DisableUsbPortMux.maxcores
.set XUD_DisableUsbPortMux.nstackwords, 0
.set XUD_DisableUsbPortMux.maxchanends, 0
.set XUD_DisableUsbPortMux.maxtimers, 0
.set XUD_DisableUsbPortMux.maxcores, 1
.set XUD_DisableUsbPortMux.locnochandec, 1
