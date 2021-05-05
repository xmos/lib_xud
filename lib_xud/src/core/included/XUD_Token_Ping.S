// Copyright 2011-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
.align 4
Pid_Ping:
#ifdef ARCH_L
    inpw      r10, res[RXD], 8;                 // Read EP Number
    shr       r10, r10, 24;                     // Shift off junk

    in         r11, res[r1];
    bt         r11, InvalidToken;               // VALID_TOKEN not high, ignore token 
#else
    #include "XUD_G_Crc.S"
#endif

LoadStatTablePing:
    ldw       r11, r5[r10]                      // Load relevant EP chanend
    bf        r11, PrimaryBufferFull_PING

.scheduling off
PrimaryBufferEmpty_PING:                        // Send ACK
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ldc          r11, USB_PIDn_ACK
    outpw        res[TXD], r11, 8
    bu           NextTokenAfterPing

PrimaryBufferFull_PING:                         // Send NAK
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ldc          r11, USB_PIDn_NAK
    outpw        res[TXD], r11, 8
    bu           NextTokenAfterPing
.scheduling default

