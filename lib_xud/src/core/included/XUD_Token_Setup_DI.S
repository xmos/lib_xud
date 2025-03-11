// Copyright 2011-2025 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include "XUD_AlignmentDefines.h"

// We received a setup token.  This is much the same as out token, apart from:
// - Can't NAK a setup
// - Data PID will always be DATA0
// - Payload will always be 8 bytes
.align FUNCTION_ALIGNMENT
Pid_Setup:
    #define  XTA_CRCADDRCHECK       xta_ep_Pid_Setup_header
    #include "XUD_CrcAddrCheck.S"
    ldaw       r7, r10[8]                       // R3 = R10 + 32. Read Past end of epAddr to epAddr_Setup
    ldw        r3, r5[r7]                       // Load relevant EP pointer
    bf         r3, XUD_Setup_BuffFull
    ldw        r1, r3[3]                        // Load buffer

XUD_Setup_LoadBuffer:
    bl         doRXData                         // RXData writes available data to buffer and does crc check.
RxRet1:
                                                // r8: Data tail size (bytes)
    xor        r1, r6, r11                      // Check for good CRC16
    bt         r1, XUD_Setup_NotReady           // Branch based on CRC good/bad

XUD_Setup_ClearStall:                           // CRC OK
                                                // Have received a Setup so clear any STALL condition on IN/OUT endpoint.
                                                // Note, we can speed this up by assuming Setup only received on EP 0
    ldaw         r6, dp[epAddr]

    ldaw         r11, r10[4]                    // R11 = R10 + 16
    ldw          r11, r6[r11]
    stw          r1, r11[10]                    // r1: 0

    ldw          r11, r6[r10]
    ldc          r6, USB_PIDn_NAK
    stw          r6, r11[10]

XUD_Setup_SendSetupAck:
    ldc        r11, USB_PIDn_ACK
xta_ep_doRXData_Ack:
    outpw      res[TXD], r11, 8

XUD_Setup_StoreTailData:                        // TODO: don't assume setups are 8 bytes + crc
    stw        r1, r5[r7]                       // Clear ready
    ldw        r11, r3[1]                       // Load chanend
xta_no_pauseE:
    out        res[r11], r4
xta_no_pauseF:
    outct      res[r11], 0                      // Send zero control token for Setup. Tail ignored since always expect 8 bytes
    bu         NextTokenAfterOut                // Go to next wait for next token

XUD_Setup_BuffFull:
    ldw        r10, sp[STACK_RXA_PORT]          // Load RxA Port ID (r1)
xta_ep_XUD_Setup_BuffFull:
    in         r11, res[r10]                    // RXA event cond = 0 TODO: Wait for RXA high first?
    setc       res[RXD], XS1_SETC_RUN_CLRBUF
    bu         NextTokenAfterOut


.align FUNCTION_ALIGNMENT
XUD_Setup_NotReady:
    bu         NextTokenAfterOut
