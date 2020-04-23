// Copyright (c) 2011-2019, XMOS Ltd, All rights reserved

// We received a setup token.  This is much the same as out token, apart from:
// - Can't NAK a setup
// - Data PID will always be DATA0
// - Payload will always be 8 bytes
.align 4
Pid_Setup:
    #include "XUD_CrcAddrCheck.S"
    ldw        r3, r5[r10]                      // Load relevant EP pointer
    bf         r3, SBuffFull
    ldw        r1, r3[3]                        // Load buffer

LoadSetupBuffer:
    bl          doRXData			            // RXData writes available data to buffer and does crc check.
                                                // r8: Data tail size (bytes)
    {clre;      eq      r1, r6, r11}            // Check for good CRC16
    bf          r1, NextTokenAfterOut           // Check for bad crc

ClearStall:                                     // CRC OK
                                                // Have received a SETUP so clear any STALL condition on IN/OUT endpoint.
    ldaw        r11, dp[handshakeTable_OUT]     // Note, we can speed this up by assuming SETUP only received on EP 0
    ldc         r6, USB_PIDn_NAK
    stw         r6, r11[r10]
    ldaw        r11, dp[handshakeTable_IN]
    stw         r6, r11[r10]

SendSetupAck:
    ldc         r11, USB_PIDn_ACK
    outpw       res[TXD], r11, 8

StoreTailData:                                  // TODO: don't assume setups are 8 bytes + crc
    ldc         r11, 0
    stw         r11, r5[r10]                    // Clear ready
    ldw         r11, r3[1]                      // Load chanend

    out         res[r11], r4
    outct       res[r11], 0                     // Send zero control token for SETUP. Tail ignored since always expect 8 bytes
    bu          NextTokenAfterOut 			    // Go to next wait for next token

SBuffFull:
    ldc         r11, 0
    ldw         r10, sp[STACK_RXA_PORT]                     // Load RxA Port ID (r1)
    in 	        r11, res[r10]			        // RXA event cond = 0 TODO: Wait for RXA high first?
    endin       r11, res[RXD]
    in          r11, res[RXD]
    bu          NextTokenAfterOut
