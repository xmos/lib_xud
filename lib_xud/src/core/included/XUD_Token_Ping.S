// Copyright 2011-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include "XUD_AlignmentDefines.h"

.align FUNCTION_ALIGNMENT
Pid_Ping:
    #include "XUD_CrcAddrCheck.S"

LoadStatTablePing:
    ldw       r11, r5[r10]                          // Load relevant EP chanend
    bf        r11, PrimaryBufferFull_PING

.scheduling off
PrimaryBufferEmpty_PING:                            // Send ACK
#if (XUD_CORE_CLOCK > 400)
    nop
    nop
    nop
#endif
    nop
    nop
    nop
    nop
    ldc          r11, USB_PIDn_ACK
    outpw        res[TXD], r11, 8
    bu           NextTokenAfterPing

PrimaryBufferFull_PING:                             // Send NAK (or STALL)
#if (XUD_CORE_CLOCK > 400)
    nop
    nop
    nop
#endif
    nop
    nop
    nop
    ldaw         r11, dp[handshakeTable_OUT]        // Load handshake table
    ldw          r11, r11[r10]                      // Load handshake (ACK or STALL)
    outpw        res[TXD], r11, 8
    bu           NextTokenAfterPing
.scheduling default

