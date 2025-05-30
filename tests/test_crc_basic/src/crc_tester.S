// Copyright 2025 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

// something like:
//void crc_tester(chanend);

// before calling the crc function, we need:
// sp[STACK_CRC5TABLE_ADDR]
// RXD pointing to the chanend
// r8 16

// on exit it will branch to XUD_InvalidToken if crc is wrong
// return r10 ep number, r4 crc_good

#define FUNCTION_NAME crc_tester

#define NSTACKWORDS (10)

#define STACK_CRC5TABLE_ADDR (8)

.globl FUNCTION_NAME
.type FUNCTION_NAME, @function
.text
.cc_top FUNCTION_NAME.func, FUNCTION_NAME

.globl FUNCTION_NAME.nstackwords
.globl FUNCTION_NAME.maxthreads
.globl FUNCTION_NAME.maxtimers
.globl FUNCTION_NAME.maxchanends

.linkset FUNCTION_NAME.nstackwords, NSTACKWORDS
.linkset FUNCTION_NAME.maxchanends, 0
.linkset FUNCTION_NAME.maxtimers,   0
.linkset FUNCTION_NAME.maxthreads,  0

#define RXD r0

.issue_mode dual
.align 4
FUNCTION_NAME:
  dualentsp NSTACKWORDS

  std r4, r5, sp[1]
  std r6, r7, sp[2]
  std r8, r9, sp[3]
  stw r10, sp[7]

  ldaw r10, dp[crc5Table_Addr]
  stw r10, sp[STACK_CRC5TABLE_ADDR]
  ldc r2, 0

.loop_top:

  ldc r8, 16

#include "XUD_CrcAddrCheck.S"

  // check the recieved ep number
  { eq r3, r2, r10  ; add r2, r2, 1   }
  { ecallf r3       ; ldc r3, 16      }
  remu r2, r2, r3

// name taken from the XUD_IoLoop.S
XUD_InvalidToken:
  { out res[r0], r8 ; bu .loop_top    }

  // will never get here but still
  ldd r4, r5, sp[1]
  ldd r6, r7, sp[2]
  ldd r8, r9, sp[3]
  ldw r10, sp[7]
  retsp NSTACKWORDS

.cc_bottom FUNCTION_NAME.func
