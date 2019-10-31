// Copyright (c) 2011-2018, XMOS Ltd, All rights reserved
#include <xs1.h>

// Ports
#define RXD r0
#define RXA r1
#define TXD r2

//.text
// On entry:
// R11: Branch address (now free)
// R10: EP number  (used here)
// R9 : CRC16 Poly (used here)
// R8 :
// R7 :
// R6 : ep_pid_sequence_table_IN_A
// R5 : Channel Array
// R4 :
// R3 : 0
// R2 : TXD
// R1 : Valid Token Port
// R0 : RXD
.align 4
InNotReady:
    ldw         r11, sp[SP_EPTYPES_OUT]
    ldw         r11, r11[r10]                       // Load EP Type
    bt          r11, XUD_IN_TxNak
    ldc         r11, 0xc3                           // Create 0-length packet
    outpw       res[TXD], r11, 24
    #include "XUD_TokenJmp.S"

XUD_IN_TxNak:                                       // Non-Iso
    ldaw       r11, dp[handshakeTable_IN]           // Load handshake table
    ldw        r11, r11[r10]                        // Load handshake PID
    outpw     res[TXD], r11, 8
    #include "XUD_TokenJmp.S"

.align 8
Pid_In:
    #include "XUD_CrcAddrCheck.S"
    ldaw       r3, r10[4]                           // R3 = R10 + 16
    ldw        r4, r5[r3]                           // Load EP structure address
    bf         r4, InNotReady                       // If 0 then not ready...

In_LoadPid:
    ldw         r11, r4[4]                          // Load PID from structure

InReady:
    ldw         r8, r4[3]                           // Load buffer

    ldw         r6, r4[7]                           // Load tail length (bytes)

    ldw         r4, r4[6]                           // Load buffer index
    bf          r4, SmallTxPacket                   // Check for Short packet

XUD_IN_Tx:
    outpw       res[TXD], r11, 8                    // Out PID
    ldw         r11, r8[r4]                         // Load first data word

XUD_IN_TxPid:
    out         res[TXD], r11
    crc32_inc   r7, r11, r9, r4, 1
    bf          r4, XUD_IN_TxLoopEnd

XUD_IN_TxLoop:
    ldw         r11, r8[r4]                         // Load first data word
    crc32_inc   r7, r11, r9, r4, 1
    {out         res[TXD], r11;     bt       r4, XUD_IN_TxLoop}

XUD_IN_TxLoopEnd:
    ldw         r11, r8[r4]                         // Load tail
    crcn        r7, r11, r9, r6
    outpw       res[TXD], r11, r6

XUD_IN_TxLoopEnd_CrcCalc:
    crc32       r7, r4, r9                          // r4: 0 (from bf)
    not         r7, r7
XUD_IN_TxCrc:
    outpw       res[TXD], r7, 16                    // Output 16-bit CRC

.scheduling default

// Wait for handshake... or timeout
DoneTail:
    ldw         r11, sp[SP_EPTYPES_OUT]
    ldw         r11, r11[r10]                       // Load EP Type
    bt          r11, SetupReceiveHandShake
    bu          DoneTx

SetupReceiveHandShake:
    ldc	       	 r11, 8
    setpsc       res[RXD], r11		                // Set port shift count (expect 8 bit handshake)
    eeu		     res[RXD]                           // Events on RXD always enabled - Can;t be any more due to using events on channels

SetupTimeout:				                        // Timeout done using another port off same clock block we dont happen to already be using events on. Cunning.
    ldw 		r1, sp[STACK_FLAG0_PORT]            // Load saved ValidToken port. Event vector already set.
    in          r11, res[r1]		                // Do input and get port time/timestamps
    getts	    r11, res[r1]
    ldw         r9, dp[g_txHandshakeTimeout]
    add         r11, r11, r9
    setpt	    res[r1], r11		                // Set port time and enable events
    eeu	        res[r1]

WaitForHandshake:			                        // Wait for timeout or handshake
    .xtabranch TxHandshakeTimeOut, TxHandShakeReceived
    waiteu

// We sent some data but the host didn't handshake in time.  Needs a re-send.
.align 4
TxHandshakeTimeOut:
    in 	    	r11, res[r1]                        // This will clear port time
    edu         res[r1]
    {edu         res[RXD]; bu          BadHandshake}

// Transmitted data, and got something back within the timeout. Check for valid handshake...
.align 4
TxHandShakeReceived:
XUD_IN_RxAck:
    in 		    r11, res[RXD]                       // Input data from RXD port
    clrpt		res[r1]			                    // Clear port time on valid token port
    {edu         res[RXD];  shr      r11, r11, 24}  // Shift off junk data to leave ACK
#if defined(__XS2A__) || defined(__XS1B__)
    ldc         r9, USB_PID_ACK                     // Check for good ACK (L series strips of negated bits from PID)
#else
    ldc         r9, USB_PIDn_ACK
#endif
    xor         r9, r11, r9
    {edu        res[r1];   bt       r9, BadHandshake}     // Disable events on ValidToken port

DoneTx:

ClearInEpReady:                                 // TODO Tidy this up
    ldc         r9, 0                           // TODO
    ldw         r10, r5[r3]                     // Load the EP struct
    stw         r9, r5[r3]                      // Clear the ready
    ldw         r11, r10[1]                     // Load channel
    out         res[r11], r11                   // Output word to signal packet sent okay
    bu        	NextToken

BadHandshake:
    bu          NextToken

.align 64
.skip 56
SmallTxPacket:
    ldw         r8, r8[r4]                      // Load first data word
    bru         r6                              // branch taillength

//--------------------------------------------------------------------------
.align 32
.skip 0
TxTail0s:                                       // We know this is a < 4 byte packet, so is 0 length packet
                                                // So crc = 0. Note our normal crc calculation works for this, it is
                                                // Not a special CRC case, but helps with timing.
    ldc        r8, 0
XUD_IN_TxPid_TailS0:
    outpw      res[TXD], r11, 8                 // PID
XUD_IN_TxCrc_TailS0:
    outpw      res[TXD], r8, 16                 // Output CRC 
    bu         DoneTail

.align 32
.skip 0
TxTail1s:                                       // One tail byte
    shl 		r6, r8, 8                       // Concat PID and Data
    or  		r11, r11, r6
    crc8        r7, r8, r8, r9
    crc32       r7, r4, r9               		// r4: 0
    not         r7, r7
XUD_IN_TxPid_TailS1:
    outpw     	res[TXD], r11, 16        		// PID
XUD_IN_TxCrc_TailS1:
    outpw       res[TXD], r7, 16
    bu           DoneTail

.align 32
.skip 0
TxTail2s:                                       // Two tail byte
    crcn        r7, r8, r9, r6                
    shl         r6, r8, 8
    crc32       r7, r4, r9                      // r4: 0
    {not        r7, r7;         or          r11, r11, r6}
XUD_IN_TxPid_TailS2:
    outpw       res[TXD], r11, 24               // Output PID and 2 bytes of data
XUD_IN_TxCrc_TailS2:
    outpw       res[TXD], r7, 16                // Output CRC16
    bu          DoneTail

.align 32
.skip 0
TxTail3s:                                       // Three tail byte
XUD_IN_TxPid_TailS3:
    outpw       res[TXD], r11, 8                // PID
    outpw       res[TXD], r8, 24
    crcn        r7, r8, r9, r6
    crc32       r7, r4, r9                      // r4: 0
    not         r7, r7
XUD_IN_TxCrc_TailS3:
    outpw       res[TXD], r7, 16
    bu          DoneTail

.align 32
.skip 0
TxTail4s:                                       // Four tail byte
XUD_IN_TxPid_TailS4:
    outpw       res[TXD], r11, 8                // PID
    out         res[TXD], r8
    crc32       r7, r8, r9                      
    crc32       r7, r4, r9                      // r4: 0
    not         r7, r7
XUD_IN_TxCrc_TailS4:
    outpw       res[TXD], r7, 16
    bu          DoneTail

