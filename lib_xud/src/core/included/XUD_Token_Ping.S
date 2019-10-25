// Copyright (c) 2011-2019, XMOS Ltd, All rights reserved
.align 4
Pid_Ping:
    #include "XUD_CrcAddrCheck.S"

LoadStatTablePing:
    ldw       r11, r5[r10]                      // Load relevant EP chanend
    bf        r11, PrimaryBufferFull_PING

.scheduling off
PrimaryBufferEmpty_PING:                        // Send ACK
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

PrimaryBufferFull_PING:                         // Send NAK
#if (XUD_CORE_CLOCK > 400)
    nop
    nop
    nop
#endif
    nop
    nop
    nop
    nop
    ldc          r11, USB_PIDn_NAK
    outpw        res[TXD], r11, 8
    bu           NextTokenAfterPing
.scheduling default

