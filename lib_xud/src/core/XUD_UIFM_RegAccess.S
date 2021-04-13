// Copyright 2011-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
/** XUD_UIFM_RegAccess.S
  * @brief     Functions for UIFM register read/write
  * @author    Ross Owen, XMOS Limited
  */

#include <xud.h>

#include "XUD_UIFM_Defines.h"
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

#if !defined (ARCH_S) && !defined (ARCH_X200)

/////////////////////////////////////////////////////////////////////////////////////////////
// unsigned XUD_UIFM_RegRead(out port reg_write_port, in port reg_read_port, unsigned regNo);
.globl XUD_UIFM_RegRead
.type XUD_UIFM_RegRead, @function
.text

.cc_top XUD_UIFM_RegRead.function
.align 4
XUD_UIFM_RegRead:

    setc        res[r1], XS1_SETC_RUN_CLRBUF
    ldc         r11, UIFM_CMD_READ         // make register ID
    or          r3, r11, r2

    out         res[r0], r3
    syncr       res[r0];
    in          r0, res[r1]

    retsp       0
.size XUD_UIFM_RegRead, .-XUD_UIFM_RegRead
.cc_bottom XUD_UIFM_RegRead.function
.globl XUD_UIFM_RegRead.nstackwords
.globl XUD_UIFM_RegRead.maxtimers
.globl XUD_UIFM_RegRead.maxchanends
.globl XUD_UIFM_RegRead.maxcores
.set XUD_UIFM_RegRead.nstackwords, 0
.set XUD_UIFM_RegRead.maxtimers, 0
.set XUD_UIFM_RegRead.maxchanends, 0
.set XUD_UIFM_RegRead.maxcores, 1


////////////////////////////////////////////////////////////////////////////////////////
// void UifmWriteRead(out port reg_write_port, unsigned regNo, unsigned val);
.globl XUD_UIFM_RegWrite
.type XUD_UIFM_RegWrite, @function

.text

.cc_top XUD_UIFM_RegWrite.function
.align 4
XUD_UIFM_RegWrite:
  ldc       r11, UIFM_CMD_WRITE
  or        r3, r11, r1

  out       res[r0], r3
  syncr     res[r0];
  out       res[r0], r2
  syncr     res[r0];

  retsp     0
.size XUD_UIFM_RegWrite, .-XUD_UIFM_RegWrite
.cc_bottom XUD_UIFM_RegWrite.function
.globl XUD_UIFM_RegWrite.nstackwords
.globl XUD_UIFM_RegWrite.maxtimers
.globl XUD_UIFM_RegWrite.maxchanends
.globl XUD_UIFM_RegWrite.maxcores
.set XUD_UIFM_RegWrite.nstackwords, 0
.set XUD_UIFM_RegWrite.maxtimers, 0
.set XUD_UIFM_RegWrite.maxchanends, 0
.set XUD_UIFM_RegWrite.maxcores, 1

// void XUD_UIFM_RegWrite_(unsigned regNo, unsigned val);
.globl XUD_UIFM_RegWrite_
.type XUD_UIFM_RegWrite_, @function

.text

.cc_top XUD_UIFM_RegWrite_.function
.align 4
XUD_UIFM_RegWrite_:
    ldc         r11, UIFM_CMD_WRITE
    or          r3, r11, r0
    ldw         r2, dp[reg_write_port]

    out         res[r2], r3
    syncr     res[r2];
    out         res[r2], r1
    syncr     res[r2];

    retsp       0
.size XUD_UIFM_RegWrite_, .-XUD_UIFM_RegWrite_
.cc_bottom XUD_UIFM_RegWrite_.function
.globl XUD_UIFM_RegWrite_.nstackwords
.globl XUD_UIFM_RegWrite_.maxtimers
.globl XUD_UIFM_RegWrite_.maxchanends
.globl XUD_UIFM_RegWrite_.maxcores
.set XUD_UIFM_RegWrite_.nstackwords, 0
.set XUD_UIFM_RegWrite_.maxtimers, 0
.set XUD_UIFM_RegWrite_.maxchanends, 0
.set XUD_UIFM_RegWrite_.maxcores, 1


#endif
#endif
