// Copyright 2011-2025 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include "XUD_AlignmentDefines.h"

.align FUNCTION_ALIGNMENT
Pid_Ping:
    #define  XTA_CRCADDRCHECK       xta_ep_Pid_Ping_header
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
xta_ep_Ping_Ack:
    outpw        res[TXD], r11, 8
    bu           NextTokenAfterPing

PrimaryBufferFull_PING:                             // Send NAK (or STALL)
#if (XUD_CORE_CLOCK > 400)
    nop
    nop
    nop
#endif

    ldaw         r11, dp[epAddr]
    ldw          r11, r11[r10]
    ldw          r11, r11[10]

xta_ep_PingNotAck:
    outpw        res[TXD], r11, 8
    bu           NextTokenAfterPing
.scheduling default

