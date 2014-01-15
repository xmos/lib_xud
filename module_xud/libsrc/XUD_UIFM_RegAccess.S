/** XUD_UIFM_RegAccess.S
  * @brief     Functions for UIFM register read/write
  * @author    Ross Owen, XMOS Limited
  * @version   0v9
  */

#define PS_XCORE_CTRL0 0x20b

#include "XUD_UIFM_Defines.h"
#include <xs1.h>

#ifndef GLX
.text

//XUD_ULPIReg(p_usb_txd);
.globl XUD_ULPIReg //"f{ui}(ui)"
.type  XUD_ULPIReg, @function
.cc_top XUD_ULPIReg.function
.align    4
XUD_ULPIReg:
  entsp     16


  ldc       r11, 0x8d
  out     res[r0], r11
looper:
  bu        looper


  retsp     16
.size XUD_ULPIReg, .-XUD_ULPIReg
.cc_bottom XUD_ULPIReg.function
.globl XUD_ULPIReg.nstackwords
.globl XUD_ULPIReg.maxchanends
.globl XUD_ULPIReg.maxtimers
.globl XUD_ULPIReg.maxcores
.set XUD_ULPIReg.nstackwords, 16
.set XUD_ULPIReg.maxchanends, 0
.set XUD_ULPIReg.maxtimers, 0
.set XUD_ULPIReg.maxcores, 1
.set XUD_ULPIReg.locnochandec, 1


.text
.globl XUD_UIFM_Enable, "f{ui}(ui)"
.type  XUD_UIFM_Enable, @function
.cc_top XUD_UIFM_Enable.function
.align    4
// void XUD_UIFM_Enable (unsigned mode);
XUD_UIFM_Enable:
  entsp     16
  stw       r10, sp[1]

  ldc       r10, PS_XCORE_CTRL0
  set       ps[r10], r0

  // Sanity check, read back and check
  get	    r10, ps[r10]
  eq        r0, r0, r10
  ecallf    r0

  ldw       r10, sp[1]
  retsp     16
.size XUD_UIFM_Enable, .-XUD_UIFM_Enable
.cc_bottom XUD_UIFM_Enable.function
.globl XUD_UIFM_Enable.nstackwords
.globl XUD_UIFM_Enable.maxchanends
.globl XUD_UIFM_Enable.maxtimers
.globl XUD_UIFM_Enable.maxcores
.set XUD_UIFM_Enable.nstackwords, 16
.set XUD_UIFM_Enable.maxchanends, 0
.set XUD_UIFM_Enable.maxtimers, 0
.set XUD_UIFM_Enable.maxcores, 1
.set XUD_UIFM_Enable.locnochandec, 1



/////////////////////////////////////////////////////////////////////////////////////////////
// unsigned UifmReadRead(out port reg_write_port, in port reg_read_port, unsigned regNo);
.globl XUD_UIFM_RegRead
.type XUD_UIFM_RegRead, @function
.text

.cc_top XUD_UIFM_RegRead.function
.align 4
XUD_UIFM_RegRead:

  ldc r11, UIFM_CMD_READ         // make register ID
  or r3, r11, r2

  out res[r0], r3
  syncr     res[r0];
  in r0, res[r1]

  retsp 0
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

#if 0
/////////////////////////////////////////////////////////////////////////////////////////////////
// unsigned UifmReadRead_Locked(out port reg_write_port, in port reg_read_port, lock l, unsigned regNo);
.globl XUD_UIFM_RegRead_Locked
.type XUD_UIFM_RegRead_Locked, @function
.text

.cc_top XUD_UIFM_RegRead_Locked.function
.align 4
XUD_UIFM_RegRead_Locked:
  in 	r2, res[r2]		// Claim lock

  ldc r11, UIFM_CMD_READ        // Construct UIFM reg ID/Read command
  or r3, r11, r3

  out res[r0], r3		// Output command
  in r0, res[r1]		// Read back result

  out   res[r2], r2		// Free lock

  retsp 0
.size XUD_UIFM_RegRead_Locked, .-XUD_UIFM_RegRead_Locked
.cc_bottom XUD_UIFM_RegRead_Locked.function
.globl XUD_UIFM_RegRead_Locked.nstackwords
.globl XUD_UIFM_RegRead_Locked.maxtimers
.globl XUD_UIFM_RegRead_Locked.maxchanends
.globl XUD_UIFM_RegRead_Locked.maxcores
.set XUD_UIFM_RegRead_Locked.nstackwords, 0
.set XUD_UIFM_RegRead_Locked.maxtimers, 0
.set XUD_UIFM_RegRead_Locked.maxchanends, 0
.set XUD_UIFM_RegRead_Locked.maxcores, 1
#endif


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


////////////////////////////////////////////////////////////////////////////////////////
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


#if 0
////////////////////////////////////////////////////////////////////////////////////////
// void UifmWriteReg_Locked(out port reg_write_port, lock l, unsigned regNo, unsigned val);
.globl XUD_UIFM_RegWrite_Locked
.type XUD_UIFM_RegWrite_Locked, @function

.text
.cc_top XUD_UIFM_RegWrite_Locked.function
.align 4
XUD_UIFM_RegWrite_Locked:

  in        r1, res[r1]

  ldc       r11, UIFM_CMD_WRITE
  or        r2, r11, r2

  out       res[r0], r2
  out       res[r0], r3

  out       res[r1], r1

  retsp     0
.size XUD_UIFM_RegWrite_Locked, .-XUD_UIFM_RegWrite_Locked
.cc_bottom XUD_UIFM_RegWrite_Locked.function
.globl XUD_UIFM_RegWrite_Locked.nstackwords
.globl XUD_UIFM_RegWrite_Locked.maxtimers
.globl XUD_UIFM_RegWrite_Locked.maxchanends
.globl XUD_UIFM_RegWrite_Locked.maxcores
.set XUD_UIFM_RegWrite_Locked.nstackwords, 0
.set XUD_UIFM_RegWrite_Locked.maxtimers, 0
.set XUD_UIFM_RegWrite_Locked.maxchanends, 0
.set XUD_UIFM_RegWrite_Locked.maxcores, 1
#endif
#endif
