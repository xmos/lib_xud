// Copyright 2011-2022 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include <xs1.h>
#include "XUD_AlignmentDefines.h"

// Ports
#define RXD r0
#define RXA r1
#define TXD r2

// On entry:
// R11: Branch address (now free)
// R10: EP number  (used here)
// R9 : CRC16 Poly (used here)
// R8 :
// R7 : Tx CRC init
// R6 : ep_pid_sequence_table_IN_A
// R5 : EP structures array
// R4 :
// R3 : 0
// R2 : TXD
// R1 : XS2: Valid Token Port, XS3: Spare!
// R0 : RXD
.align FUNCTION_ALIGNMENT
XUD_IN_NotReady:
    ldw         r11, sp[STACK_EPTYPES_IN]
    ldw         r11, r11[r10]                      // Load EP Type
    bt          r11, XUD_IN_TxHandshake
    ldc         r11, 0xc3                          // Create 0-length packet
    outpw       res[TXD], r11, 24
    #include "XUD_TokenJmp.S"

XUD_IN_TxHandshake:                                // Non-Iso
    ldaw        r11, dp[epAddr]
    ldw         r11, r11[r3]
    ldw         r11, r11[10]

    bf          r11, XUD_IN_TxNak
XUD_IN_TxStall:
    outpw       res[TXD], r11, 8                    // Output STALL
    #include "XUD_TokenJmp.S"

XUD_IN_TxNak:
    ldc         r11, USB_PIDn_NAK
    outpw       res[TXD], r11, 8
    #include "XUD_TokenJmp.S"

.align FUNCTION_ALIGNMENT
Pid_In:
    #include "XUD_CrcAddrCheck.S"
    ldaw       r3, r10[4]                          // R3 = R10 + 16
    ldw        r4, r5[r3]                          // Load EP structure address
    bf         r4, XUD_IN_NotReady
    ldw        r1, r4[4]                           // Load PID from structure

XUD_IN_Ready:
    ldw        r8, r4[3]                           // Load buffer
    ldw        r6, r4[7]                           // Load tail length (bytes)
    ldw        r4, r4[6]                           // Load data length (words)
    bf         r4, XUD_IN_SmallTxPacket            // Check for Short packet

XUD_IN_Tx:
    ldw        r11, r8[r4]                         // Load first data word
    crc32_inc  r7, r11, r9, r4, 1
    outpw      res[TXD], r1, 8                     // Out PID

XUD_IN_Loop0:
    {out         res[TXD], r11;     bf        r4, XUD_IN_TxLoopEnd}

XUD_IN_TxLoop:
    ldw         r11, r8[r4]                         // Load first data word
    crc32_inc   r7, r11, r9, r4, 1
    {out         res[TXD], r11;     bt       r4, XUD_IN_TxLoop}

XUD_IN_TxLoopEnd:
    ldw         r11, r8[r4]                         // Load tail
    crcn        r7, r11, r9, r6

XUD_IN_TxLoopEnd_CrcCalc:
    crc32       r7, r4, r9                          // r4: 0 (from bf)
    outpw       res[TXD], r11, r6
    not         r7, r7
XUD_IN_TxCrc:
    outpw       res[TXD], r7, 16                    // Output 16-bit CRC

.scheduling default

// Wait for handshake... or timeout
DoneTail:
    ldw         r11, sp[STACK_EPTYPES_IN]
    ldw         r11, r11[r10]                       // Load EP Type
    bt          r11, SetupReceiveHandShake
    bu          XUD_IN_DoneTx

SetupReceiveHandShake:
    ldc        r11, 8
    setpsc     res[RXD], r11                       // Set port shift count (expect 8 bit handshake)

SetupTimeout:                                      // Timeout done using another port we dont happen to already be using events on. Cunning.
#ifdef __XS2A__
    ldw        r1, sp[STACK_VTOK_PORT]             // Load saved ValidToken port. Event vector already set.
#else
    ldw        r1, dp[rx_rdy]                      // TODO load from stack
#endif
    eeu        res[RXD]                            // Events on RXD always enabled - Can't be any more due to using events on channels

    in         r11, res[r1]                        // Do input and get port time/timestamps
    getts      r11, res[r1]
    ldw        r9, dp[g_txHandshakeTimeout]
    add        r11, r11, r9
    setpt      res[r1], r11                        // Set port time and enable events
    eeu        res[r1]

WaitForHandshake:                                  // Wait for timeout or handshake
    .xtabranch TxHandshakeTimeOut, TxHandShakeReceived
    waiteu

// We sent some data but the host didn't handshake in time.  Needs a re-send.
.align FUNCTION_ALIGNMENT
TxHandshakeTimeOut:
    clre
    in         r11, res[r1]                        // This will clear port time
    bu        BadHandshake

// Transmitted data, and got something back within the timeout. Check for valid handshake...
.align FUNCTION_ALIGNMENT
TxHandShakeReceived:
    clre
    in         r11, res[RXD]                       // Input data from RXD port
    {clrpt     res[r1];                            // Clear port time on valid token port
    shr        r11, r11, 24}                       // Shift off junk data to leave ACK
#if defined(__XS2A__)
    ldc        r9, USB_PID_ACK                     // Check for good ACK (L series strips negated bits from PID)
#else
    ldc        r9, USB_PIDn_ACK
#endif
    xor        r9, r11, r9
    bt         r9, BadHandshake

XUD_IN_DoneTx:

ClearInEpReady:                                    // TODO Tidy this up
    ldc        r9, 0                               // TODO
    ldw        r10, r5[r3]                         // Load the EP struct
    stw        r9, r5[r3]                          // Clear the ready
    ldw        r11, r10[1]                         // Load channel
    out        res[r11], r11                       // Output word to signal packet sent okay
    bu         NextToken

BadHandshake:
    bu          NextToken

.align 64
.skip 56
XUD_IN_SmallTxPacket:
    ldw         r8, r8[r4]                         // Load first data word
    bru         r6                                 // Branch on tail-length

//--------------------------------------------------------------------------
.align 32
.skip 0
TxTail0s:                                          // We know this is a < 4 byte packet, so is 0 length packet
                                                   // So crc = 0. Note our normal crc calculation works for this, it is
                                                   // Not a special CRC case, but helps with timing.
XUD_IN_TxPid_TailS0:
    outpw      res[TXD], r1, 8                      // PID
XUD_IN_TxCrc_TailS0:
    outpw      res[TXD], r4, 16                     // Output CRC
    bu         DoneTail

.align 32
.skip 0
TxTail1s:                                           // One tail byte
    crcn       r7, r8, r9, r6
    crc32      r7, r4, r9                           // r4: 0
XUD_IN_TxPid_TailS1:
    not        r7, r7
    outpw      res[TXD], r1, 8                      // Output PID
    outpw      res[TXD], r8, 8                      // Output data[0]
XUD_IN_TxCrc_TailS1:
    outpw      res[TXD], r7, 16
    bu         DoneTail

.align 32
.skip 0
TxTail2s:                                           // Two tail byte
    crcn        r7, r8, r9, r6
    crc32       r7, r4, r9                          // r4: 0
XUD_IN_TxPid_TailS2:
    outpw       res[TXD], r1, 8                     // Output PID
    outpw       res[TXD], r8, 16                    // Output data[0:1]
    not         r7, r7
XUD_IN_TxCrc_TailS2:
    outpw       res[TXD], r7, 16                    // Output CRC16
    bu          DoneTail

.align 32
.skip 0
TxTail3s:                                           // Three tail byte
XUD_IN_TxPid_TailS3:
    outpw       res[TXD], r1, 8                     // PID
    outpw       res[TXD], r8, 24
    crcn        r7, r8, r9, r6
    crc32       r7, r4, r9                          // r4: 0
    not         r7, r7
XUD_IN_TxCrc_TailS3:
    outpw       res[TXD], r7, 16
    bu          DoneTail

.align 32
.skip 0
TxTail4s:                                           // Four tail byte
XUD_IN_TxPid_TailS4:
    outpw       res[TXD], r1, 8                     // PID
    out         res[TXD], r8
    crc32       r7, r8, r9
    crc32       r7, r4, r9                          // r4: 0
    not         r7, r7
XUD_IN_TxCrc_TailS4:
    outpw       res[TXD], r7, 16
    bu          DoneTail
