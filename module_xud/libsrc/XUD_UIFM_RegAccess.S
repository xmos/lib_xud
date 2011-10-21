/** XUD_UIFM_RegAccess.S
  * @brief     Functions for UIFM register read/write
  * @author    Ross Owen, XMOS Limited
  * @version   0v9
  */

#define PS_XCORE_CTRL0 0x20b

#include "XUD_UIFM_Defines.h"
#include <xs1.h>

.text
.align    2

//XUD_ULPIReg(p_usb_txd); 
.globl XUD_ULPIReg //"f{ui}(ui)"
.globl XUD_ULPIReg.nstackwords
.globl XUD_ULPIReg.maxthreads
.globl XUD_ULPIReg.maxtimers
.globl XUD_ULPIReg.maxchanends
.globl XUD_ULPIReg.maxsync
.type  XUD_ULPIReg, @function
.linkset XUD_ULPIReg.locnoside, 1
.linkset XUD_ULPIReg.locnochandec, 1
.linkset XUD_ULPIReg.nstackwords, 16
.cc_top XUD_ULPIReg.function,XUD_ULPIReg
.align    4


XUD_ULPIReg:
  entsp     16
 
 
  ldc       r11, 0x8d
  out     res[r0], r11
looper:
  bu        looper 
  
  
  retsp     16
.cc_bottom XUD_ULPIReg.function
.linkset XUD_ULPIReg.maxchanends, 0
.linkset XUD_ULPIReg.maxtimers, 0
.linkset XUD_ULPIReg.maxthreads, 1


.text
.align    2
.globl XUD_UIFM_Enable, "f{ui}(ui)"
.globl XUD_UIFM_Enable.nstackwords
.globl XUD_UIFM_Enable.maxthreads
.globl XUD_UIFM_Enable.maxtimers
.globl XUD_UIFM_Enable.maxchanends
.globl XUD_UIFM_Enable.maxsync
.type  XUD_UIFM_Enable, @function
.linkset XUD_UIFM_Enable.locnoside, 1
.linkset XUD_UIFM_Enable.locnochandec, 1
.linkset XUD_UIFM_Enable.nstackwords, 16
.cc_top XUD_UIFM_Enable.function,XUD_UIFM_Enable
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
.cc_bottom XUD_UIFM_Enable.function
.linkset XUD_UIFM_Enable.maxchanends, 0
.linkset XUD_UIFM_Enable.maxtimers, 0
.linkset XUD_UIFM_Enable.maxthreads, 1



/////////////////////////////////////////////////////////////////////////////////////////////
// unsigned UifmReadRead(out port reg_write_port, in port reg_read_port, unsigned regNo);
.extern XUD_UIFM_RegRead
.globl XUD_UIFM_RegRead.nstackwords
.linkset XUD_UIFM_RegRead.nstackwords, 0
.globl XUD_UIFM_RegRead
.text
.align 4
.skip 0

XUD_UIFM_RegRead:
 
  ldc r11, UIFM_CMD_READ         // make register ID
  or r3, r11, r2  
  
  out res[r0], r3
  syncr     res[r0];
  in r0, res[r1]
  
  retsp 0


#if 0
/////////////////////////////////////////////////////////////////////////////////////////////////
// unsigned UifmReadRead_Locked(out port reg_write_port, in port reg_read_port, lock l, unsigned regNo);
.extern XUD_UIFM_RegRead_Locked
.globl XUD_UIFM_RegRead_Locked.nstackwords
.linkset XUD_UIFM_RegRead_Locked.nstackwords, 0
.globl XUD_UIFM_RegRead_Locked
.text
.align 4
.skip 0
XUD_UIFM_RegRead_Locked:
  in 	r2, res[r2]		// Claim lock
 
  ldc r11, UIFM_CMD_READ        // Construct UIFM reg ID/Read command 
  or r3, r11, r3  
  
  out res[r0], r3		// Output command
  in r0, res[r1]		// Read back result
  
  out   res[r2], r2		// Free lock

  retsp 0
#endif


////////////////////////////////////////////////////////////////////////////////////////
// void UifmWriteRead(out port reg_write_port, unsigned regNo, unsigned val);
.extern XUD_UIFM_RegWrite
.globl XUD_UIFM_RegWrite.nstackwords
.linkset XUD_UIFM_RegWrite.nstackwords, 0
.globl XUD_UIFM_RegWrite
  
.text
.align 4

XUD_UIFM_RegWrite:
  ldc       r11, UIFM_CMD_WRITE
  or        r3, r11, r1

  out       res[r0], r3
  syncr     res[r0];
  out       res[r0], r2
  syncr     res[r0];

  retsp     0


////////////////////////////////////////////////////////////////////////////////////////
// void XUD_UIFM_RegWrite_(unsigned regNo, unsigned val);
.extern XUD_UIFM_RegWrite_
.globl XUD_UIFM_RegWrite_.nstackwords
.linkset XUD_UIFM_RegWrite_.nstackwords, 0
.globl XUD_UIFM_RegWrite_
  
.text
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


#if 0
////////////////////////////////////////////////////////////////////////////////////////
// void UifmWriteReg_Locked(out port reg_write_port, lock l, unsigned regNo, unsigned val);
.extern XUD_UIFM_RegWrite_Locked
.globl XUD_UIFM_RegWrite_Locked.nstackwords
.linkset XUD_UIFM_RegWrite_Locked.nstackwords, 0
.globl XUD_UIFM_RegWrite_Locked
  
.text
.align 4
XUD_UIFM_RegWrite_Locked:

  in        r1, res[r1]

  ldc       r11, UIFM_CMD_WRITE
  or        r2, r11, r2

  out       res[r0], r2
  out       res[r0], r3

  out       res[r1], r1

  retsp     0
#endif
