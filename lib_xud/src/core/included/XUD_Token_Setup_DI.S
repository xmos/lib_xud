// Copyright (c) 2011-2019, XMOS Ltd, All rights reserved

.text

// r3: Ep structure
// r5: buffer address
// RXD: Rx Data port
// r4: zero
// r5: ep structures array
// r6: crc rx init
// r7: crc tx init
// r9: crc poly
// r10: ep number
// r11: scratch
.align 4
.skip 0
doRXData:
    ldw         r7, sp[10]           	                    // Load RxA Port ID (r1)
    inpw        r8, res[r0], 8                              // Input PID
GotRxPid:
    {stw       r8, r3[6];         eeu        res[r7]}       // Store (NON-SHIFTED) PID into EP structure
    setsr      1                                            // Enable thread events

NextRxWord:				                                    // RXD port has event vector here
    in 	        r11, res[r0]
    stw         r11, r1[r4]
    crc32_inc   r6, r11, r9, r4, 1 
    bu          NextRxWord

/////////////////////////////////////////////////////////////////////////////
.align 32
.skip 16
RxALow:
    in          r7, res[r7]                   // Clear event data on RXA
    endin       r8, res[r0]
XUD_OUT_RxTail:
    {in          r11, res[r0];      bru      r8}  

// Word aligned data (0 byte tail)
.align 32
OutTail0:
    crc32       r6, r8, r9                      // CRC zero step
    ldw         r11, sp[STACK_RXCRC_TAIL0]
    RETSP_u6    0

// 1 Tail Byte
.align 32
OutTail1:
    shr         r11, r11, 24                    // Shift off junk
    crc32       r6, r11, r9
    stw         r11, r1[r4]                     // Store last data
    LDWSP_ru6   r11, sp[STACK_RXCRC_TAIL1]
    RETSP_u6    0

// Two Tail Bytes
.align 32
OutTail2:
    shr         r11, r11, 16
    crc32       r6, r11, r9
    stw         r11, r1[r4]                      // Store last data
    ldw         r11, sp[STACK_RXCRC_TAIL2]
    RETSP_u6    0

// Three Tail Bytes
.align 32
OutTail3:
    shr         r11, r11, 8
    stw         r11, r1[r4]                     // Store last data
    crc32       r6, r11, r9
    LDWSP_ru6   r11, sp[STACK_RXCRC_TAIL3]
    crc8        r6, r1, r2, r9                  // Use the fact the the bottom byte of port id is 0.. saves us an ldc
    RETSP_u6    0

// Four Tail Bytes
.align 32
OutTail4:
    bu          ERR_EndIn4

// Five Tail Bytes
.align 32
OutTail5:
    bu          ERR_EndIn5


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
    ldw         r10, sp[10]                     // Load RxA Port ID (r1)
    in 	        r11, res[r10]			        // RXA event cond = 0 TODO: Wait for RXA high first?
    endin       r11, res[RXD]
    in          r11, res[RXD]
    bu          NextTokenAfterOut
