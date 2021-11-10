// Copyright 2020-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include <xs1.h>
#include "XUD_USB_Defines.h"
#include "XUD_AlignmentDefines.h"

.issue_mode dual

.globl XUD_UsbTestSE0.nstackwords
.linkset XUD_UsbTestSE0.nstackwords, 0
.globl XUD_UsbTestSE0
.text
.cc_top XUD_UsbTestSE0.func, XUD_UsbTestSE0

// NAK every IN token if the CRC is correct.

.align FUNCTION_ALIGNMENT
XUD_UsbTestSE0:
    DUALENTSP_lu6  0                                        // Note, don't really need DI here..
                                                            // TODO ideally don't load these from dp..
    ldw         r0, dp[p_usb_rxd]                           // Load RXD port
    ldw         r2, dp[p_usb_txd]                           // Load TXD port
    ldw         r3, dp[flag1_port]                          // Load RXA port

XUD_UsbTestSE0_loop:
#ifdef __XS2A__
    ldw         r1, dp[flag2_port]                          // Valid token port

    inpw        r11, res[r0], 8                             // Read 8 bit PID
    shr         r11, r11, 24                                // shift off junk

    inpw        r9, res[r0], 8                              // Read EP Number (dont care)

    in          r9, res[r1]
    bt          r9, InvalidTestToken                        // If VALID_TOKEN high, ignore token

    eq          r10, r11, USB_PID_IN
    bf          r10, XUD_UsbTestSE0_loop
#else
    ldc         r8, 16
    inpw        r11, res[r0], 8                            // Read 3 byte token from data port | CRC[5] | EP[4] | ADDR[7] | PID[8] | junk
    {setpsc     res[r0], r8;       shr      r11, r11, 24}
                                                           // TODO ideally share this with XUD_CrcAddrCheck rather than a duplication here..
    {in          r10, res[r0];     sub      r1, r8, 5}     // ldc r1, 11
    {shr        r10, r10, 16;      mkmsk    r11, r1}
    {and        r11, r10, r11;     shr      r4, r10, r1}   // r4: Received CRC

    ldaw        r8, dp[crc5Table_Addr]
    ld8u        r8, r8[r11]                                // Correct CRC

    xor         r4, r4, r8                                 // Check received CRC against expected CRC
    bt          r4, InvalidTestToken;                      // Note, EP number is ignored

    ldc         r4, USB_PIDn_IN
    eq          r11, r11, r4                               // Check received PID
    bf          r11, XUD_UsbTestSE0_loop
#endif

    nop                                                    // If all is well respond with a NAK to any IN token..
    nop
    nop
    nop
    nop

    ldc         r11, USB_PIDn_NAK
	outpw       res[r2], r11, 8
	syncr       res[r2]
    bu          XUD_UsbTestSE0_loop

InvalidTestToken:
    in          r11, res[r3]
    bt          r11, InvalidTestToken
    setc        res[r0], XS1_SETC_RUN_CLRBUF                // Clear RXD port
    bu          XUD_UsbTestSE0_loop


.cc_bottom XUD_UsbTestSE0.func
