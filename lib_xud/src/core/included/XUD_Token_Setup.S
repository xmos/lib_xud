// Copyright (c) 2011-2019, XMOS Ltd, All rights reserved

.text

#if 0
WaitForEndDataPacket:
    ldw        r10, sp[10]           		    // Load RxA Port ID (r1)
    in         r11, res[r10]
    bt         r11, waitforRXALow
    setc       res[RXD], XS1_SETC_RUN_CLRBUF
    bu         NextTokenAfterOut
#endif

// We received a setup token.  This is much the same as out token, apart from:
// - Can't NAK a setup
// - Data PID will always be DATA0
// - Payload will always be 8 bytes

.align 4
Pid_Setup:
#ifdef ARCH_L
    inpw      r10, res[RXD], 8;                 // Read EP Number 
    shr       r10, r10, 24;                     // Shift off junk

    in         r4, res[r1];
    bt         r4, XUD_InvalidToken;                // If VALID_TOKEN not high, ignore token - PORT INVERTED 
#else
    #include "XUD_G_Crc.S"
#endif
    ldw        r3, r5[r10]                      // Load relevant EP pointer
    bf         r3, SBuffFull
    ldw        r1, r3[3]                        // Load buffer


SetupReady:
    //ldw       r10, sp[10]                     // Load RxA Port ID (r1)
                                                // TODO Do a timeout here?

LoadSetupBuffer:
    bl          doRXData			            // RXData writes available data to buffer and does crc check.
                                                // r8: Data tail size (bytes)
    clre
    eq          r1, r6, r11                     // Check for good CRC16
    bf          r1, NextTokenAfterOut           // Check for bad crc

ClearStall:                                     // CRC OK
                                                // Have received a SETUP so clear any STALL condition on IN/OUT endpoint.
    ldaw        r11, dp[handshakeTable_OUT]
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
    ldw         r10, sp[10]                     // Load RxA Port ID (r1)
    in 	        r11, res[r10]			        // RXA event cond = 0 TODO: Wait for RXA high first?
    endin       r11, res[RXD]
    in          r11, res[RXD]

    bu          NextTokenAfterOut

BadDataCrcSetup:
    mov r0, r1
    bl          ERR_BadCrc
    outct       res[r5], 9
    in          r11, res[r5]                    // TODO should only need CT
    bu          NextToken
