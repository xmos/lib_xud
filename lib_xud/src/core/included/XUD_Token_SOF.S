// Copyright 2011-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
//.cc_top Pid_Sof.func, Pid_Sof
// Received SOF token: Reset suspend/reset detection timer

.align 4
Pid_Sof:
#ifdef ARCH_L
    inpw        r10, res[RXD], 8                // Read EP Number
    shr         r10, r10, 24;                   // Shift off junk

    in          r11, res[r1];
    bt          r11, InvalidToken;              // If VALID_TOKEN not high, ignore token

#else
//#include "XUD_G_Crc.S"
    in          r10, res[RXD]                   // Input Frame number
#endif
    clrsr       0x3
    ldw         r11, sp[(STACK_EXTEND+9)]

    out         res[r11], r10

    ldw         r10, sp[14]                     // Load timer from stack
    setc        res[r10], XS1_SETC_COND_NONE    // Read current time

    ldw         r8, sp[13]                      // Add suspend timeout to current time
    in          r11, res[r10]
    add         r11, r11, r8
    setd        res[r10], r11

    setc        res[r10], XS1_SETC_COND_AFTER   // Re-enable thread interrupts
    setsr       0x3

	bu          Loop_BadPid

//.cc_bottom Pid_Sof.func


//.cc_top Pid_Sof_NoChan.func, Pid_Sof_NoChan

// Received SOF token: Reset suspend/reset detection timer
.align 4
Pid_Sof_NoChan:
#ifdef ARCH_L
    inpw      r10, res[RXD], 8;                        /* Read EP Number */
    shr       r10, r10, 24;                            /* Shift off junk */

    in         r11, res[r1];
    bt         r11, InvalidToken;                       /* If VALID_TOKEN not high, ignore token */

//bl printintln
#else
//#include "XUD_G_Crc.S"
    in          r10, res[RXD]                   // Input Frame number
#endif
    clrsr       0x3
    ldw         r10, sp[14]                      // Load timer from stack
    setc        res[r10], XS1_SETC_COND_NONE    // Read current time
    ldw         r8, sp[13]
    in          r11, res[r10]
    add         r11, r11, r8
    setd        res[r10], r11
    ldw         r8, sp[13]
    setc        res[r10], XS1_SETC_COND_AFTER    // Re-enable thread interrupts
    setsr       0x3
	bu          Loop_BadPid


//.cc_bottom Pid_Sof_NoChan.func



