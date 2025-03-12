// Copyright 2011-2025 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include "XUD_AlignmentDefines.h"

// Received SOF token: Reset suspend/reset detection timer
.align FUNCTION_ALIGNMENT
Pid_Sof:
#ifdef __XS2A__
    inpw        r10, res[RXD], 8                // Read EP Number
    shr         r10, r10, 24;                   // Shift off junk

    in          r11, res[r1];
    bt          r11, XUD_InvalidToken;          // If VALID_TOKEN not high, ignore token

#else
    // NOTE: we are not CRC checking SOF's
xta_ep_Pid_Sof_header:
    in          r10, res[RXD]                   // Input Frame number
    shr         r10 , r10, 16                   // Shift off port junk
    ldc         r11, 0x7ff                      // Remove CRC5
    and         r10, r10, r11

#endif
    clrsr       0x3
    ldw         r11, sp[STACK_SOFCHAN]
xta_no_pauseP:
    out         res[r11], r10

    ldw         r10, sp[STACK_SUSPEND_TIMER]                     // Load timer from stack
    setc        res[r10], XS1_SETC_COND_NONE    // Read current time

    ldw         r8, sp[STACK_SUSPEND_TIMEOUT]   // Add suspend timeout to current time
xta_no_pauseN:
    in          r11, res[r10]
    add         r11, r11, r8
    setd        res[r10], r11

    setc        res[r10], XS1_SETC_COND_AFTER   // Re-enable thread interrupts
    setsr       0x2

    bu          Loop_BadPid

// Received SOF token: Reset suspend/reset detection timer
.align FUNCTION_ALIGNMENT
Pid_Sof_NoChan:
#ifdef __XS2A__
    inpw      r10, res[RXD], 8;                        /* Read EP Number */
    shr       r10, r10, 24;                            /* Shift off junk */

    in         r11, res[r1];
    bt         r11, XUD_InvalidToken;                       /* If VALID_TOKEN not high, ignore token */

#else
xta_ep_Pid_SofNC_header:
    in          r10, res[RXD]                   // Input Frame number
#endif
    clrsr       0x3
    ldw         r10, sp[STACK_SUSPEND_TIMER]    // Load timer from stack
    setc        res[r10], XS1_SETC_COND_NONE    // Read current time
    ldw         r8, sp[STACK_SUSPEND_TIMEOUT]
xta_no_pauseM:
    in          r11, res[r10]
    add         r11, r11, r8
    setd        res[r10], r11
    ldw         r8, sp[STACK_SUSPEND_TIMEOUT]
    setc        res[r10], XS1_SETC_COND_AFTER    // Re-enable thread interrupts
    setsr       0x2
    bu          Loop_BadPid





