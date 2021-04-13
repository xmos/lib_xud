// Copyright 2011-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
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



.align 128
#ifdef ARCH_L
.skip 92
//.skip 98
#else
.skip 78
#endif
Pid_In:
#ifdef ARCH_L
    inpw      r10, res[RXD], 8;                 // Read EP Number
    shr       r10, r10, 24;                     // Shift off junk

    in         r11, res[r1];
    bt         r11, InvalidToken;               // If VALID_TOKEN not high, ignore token - PORT INVERTED! */
#else
    #include "XUD_G_Crc.S"
#endif
    //add        r3, r4, r10                      // IN channel offset (R10: EP number, E4: Num out Eps)
    ldaw       r3, r10[4]                       // R3 = R10 + 16
    ldw        r4, r5[r3]                       // Load EP structure address
    bf         r4, InNotReady                   // If 0 then not ready...

In_LoadPid:
    ldw         r11, r4[4]                      // Load PID from structure

InReady:
    ldw         r8, r4[3]                       // Load buffer

    ldw         r6, r4[7]                       // Load tail length (bytes)

    ldw         r4, r4[6]                       // Load buffer index
    bf          r4, SmallTxPacket               // Check for Short packet

.xtabranch TxTail0, TxTail1, TxTail2, TxTail3
    bru         r6                              // Branch on tail length

//--------------------------------------------------------------------------
.align 64
.skip 0
TxTail0:
    ldw         r6, r8[r4]                      // Load first data word
    add         r4, r4, 1                       // Buffer index increment
XUD_IN_TxPid_Tail0:
    outpw       res[TXD], r11, 8                // Output PID to port
    out         res[TXD], r6                    // Output first data word
    crc32       r7, r6, r9                      // Run CRC
    bf          r4, TxLoop0End
TxLoop0:
    ldw         r6, r8[r4]                      // Load last data word
    add         r4, r4, 1
TxLoop0_Out:
    out         res[TXD], r6                    // Output last data word
    crc32       r7, r6, r9
    bt          r4, TxLoop0
TxLoop0End:                                     // Word aligned data (just output CRC)
    crc32       r7, r4, r9                      // R4: 0 (from bt)
    not         r7, r7

XUD_IN_TxCrc_Tail0:
    outpw        res[TXD], r7, 16               // Output CRC
    bu           DoneTail

.align 64
.skip 0
TxTail1:
    ldw         r6, r8[r4]                      // Load first data word
    add         r4, r4, 1                       // Buffer index increment
XUD_IN_TxPid_Tail1:
    outpw    res[TXD], r11, 8                   // Out PID
    out      res[TXD], r6
    crc32         r7, r6, r9
    bf            r4, TxLoop1End
TxLoop1:
    ldw         r6, r8[r4]                      // Load last data word
    add         r4, r4, 1
    out         res[TXD], r6
    crc32       r7, r6, r9
    bt          r4, TxLoop1
TxLoop1End:
    ldw         r6, r8[r4]                      // Load last data word
    outpw       res[TXD], r6, 8
    crc8        r7, r6, r6, r9
    crc32       r7, r4, r9                      // r4: 0 (from bf)
    not         r7, r7

XUD_IN_TxCrc_Tail1:
    outpw        res[TXD], r7, 16
    bu           DoneTail

.scheduling off
.align 64
.skip 0
TxTail2:
    ldw         r6, r8[r4]                        // Load first data word
    crc32       r7, r6, r9
XUD_IN_TxPid_Tail2:
    outpw       res[TXD], r11, 8                   // Out PID
    out         res[TXD], r6
    add         r4, r4, 1
    bf          r4, TxLoop2End
TxLoop2:
    ldw         r6, r8[r4]                        // Load first data word
    add         r4, r4, 1
    crc32       r7, r6, r9
    out         res[TXD], r6
    bt          r4, TxLoop2

TxLoop2End:
    ldw         r6, r8[r4]                      // Load tail
    crc8        r7, r11, r6, r9
    outpw       res[TXD], r6, 16
    crc8        r7, r11, r11, r9
    crc32       r7, r4, r9                      // r4: 0 (from bf)
    not         r7, r7

XUD_IN_TxCrc_Tail2:
    outpw       res[TXD], r7, 16
    bu          DoneTail

.align 64
.skip 0
TxTail3:
    ldw         r6, r8[r4]                      // Load first data word
    add         r4, r4, 1
XUD_IN_TxPid_Tail3:
    outpw    res[TXD], r11, 8                   // Out PID
    out      res[TXD], r6
    crc32      r7, r6, r9
    bf         r4, TxLoop3End
TxLoop3:
    ldw         r6, r8[r4]                      // Load first data word
    add         r4, r4, 1
    crc32       r7, r6, r9
    out         res[TXD], r6
    bt          r4, TxLoop3
TxLoop3End:
    ldw          r6, r8[r4]                     // Load tail
    crc8         r7, r11, r6, r9
    outpw        res[TXD], r6, 24
    crc8         r7, r11, r11, r9
    crc8         r7, r11, r11, r9
    crc32        r7, r4, r9                     // r4: 0 (from bf)
    not          r7, r7
XUD_IN_TxCrc_Tail3:
    outpw        res[TXD], r7, 16

.scheduling default
// Wait for handshake... or timeout
DoneTail:
    ldw         r11, sp[SP_EPTYPES_OUT]
    ldw         r11, r11[r10]                   // Load EP Type
    bt          r11, SetupReceiveHandShake

InISO:
    ldc         r9, 0    //TODO
    bu DoneTx

InNonISO:
SetupReceiveHandShake:
    ldc	       	 r11, 8
    setpsc       res[RXD], r11		            // Set port shift count (expect 8 bit handshake)
    //ldap         r11,  TxHandShakeReceived
    //setv         res[RXD], r11
    eeu		     res[RXD]                       // Events on RXD always enabled - Can;t be any more due to using events on channels

SetupTimeout:				                    // Timeout done using another port off same clock block we dont happen to already be using events on. Cunning.
    ldw 		r1, sp[STACK_FLAG0_PORT]        // Load saved ValidToken port. Event vector already set.
    in          r11, res[r1]		            // Do input and get port time/timestamps
    getts	    r11, res[r1]
    ldw         r9, dp[g_txHandshakeTimeout]
    add         r11, r11, r9
    setpt	    res[r1], r11		            // Set port time and enable events
    eeu	        res[r1]

WaitForHandshake:			                    // Wait for timeout or handshake
    .xtabranch TxHandshakeTimeOut, TxHandShakeReceived
    waiteu


// We sent some data but the host didn't handshake in time.  Needs a re-send.
.align 4
TxHandshakeTimeOut:
    in 	    	r11, res[r1]                    // This will clear port time
    edu         res[r1]
    edu         res[RXD]
    bu          BadHandShake

    //ldc         r11, 1
    //out         res[r5], r11
    //bu        	NextToken

// Transmitted data, and got something back within the timeout. Check for valid handshake...
.align 4
TxHandShakeReceived:
XUD_IN_RxAck:
    in 		    r11, res[RXD]                   // Input data from RXD port
    clrpt		res[r1]			                // Clear port time on valid token port
    edu         res[RXD]
    shr         r11, r11, 24                    // Shift off junk data to leave ACK
#ifdef ARCH_L
    ldc         r9, USB_PID_ACK                     // Check for good ACK (L series strips of negated bits from PID)
#else
    ldc         r9, USB_PIDn_ACK
#endif
    xor         r9, r11, r9
    edu         res[r1]                         // Disable events on ValidToken port
    bt          r9, BadHandShake                // Invalid handshake received from host. we need to resend...

DoneTx:
    //ldap        r11, NextRxWord                 // Restore RXD event vector
    //setv        res[RXD], r11

ClearInEpReady:                                 // TODO Tidy this up
    //ldw         r4, sp[(STACK_EXTEND+8)]      / Load num out EPs
    //add         r11, r4, r10                  // IN channel offset (R10: EP number)

    ldw         r10, r5[r3]                     // Load the EP struct
    stw         r9, r5[r3]                      // Clear the ready
    ldw         r11, r10[1]                     // Load channel
    out         res[r11], r11                   // Output word to signal packet sent okay

    bu        	NextToken

BadHandShake:			                        // Received a bad (or no)handshake
    //ldap        r11, NextRxWord                 // Restore RXD event vector
    //setv        res[RXD], r11
    bu 		    NextToken

.align 32
.skip 28
SmallTxPacket:
    ldw          r8, r8[r4]                        // Load first data word
//    inct       r8, res[r5]                      // Input tail length + 10
    //inct       r6, res[r5]                      // get end of packet token
    //sub        r8, r8, 10
    //in         r6, res[r5]                      // Input tail data
    //shl        r8, r8, 4                        // Tail length bytes to bits *2

//    shr        r8, r8, 1

    .xtabranch TxTail0s, TxTail1s, TxTail2s, TxTail3s
    bru         r6                              // branch taillength

//--------------------------------------------------------------------------
.align 64
.skip 0
TxTail0s:                                       // We know this is a < 4 byte packet, so is 0 length packet
                                                // So crc = 0. Note our normal crc calculation works for this, it is
                                                //not a special CRC case, but helps with timing.
    ldc        r8, 0
XUD_IN_TxPid_TailS0:
    outpw      res[TXD], r11, 8                 // PID
    //crc32    r7, r11, r9                      // r11: 0
    //not      r7, r7

XUD_IN_TxCrc_TailS0:
    outpw      res[TXD], r8, 16                 // r5: 0
    bu         DoneTail

.align 64
.skip 0
TxTail1s:
    ldc        	r6, 0
    // One tail byte
    shl 		r8, r8, 8                       // Concat PID and Data
    or  		r11, r11, r8
    shr 		r8, r8, 8
    crc8        r7, r4, r8, r9
    crc32       r7, r6, r9               		// r5: 0
    not         r7, r7

XUD_IN_TxPid_TailS1:
    outpw     	res[TXD], r11, 16        		// PID
    ///outpw       res[TXD], r6, 16
XUD_IN_TxCrc_TailS1:
    outpw       res[TXD], r7, 16
    bu           DoneTail

.align 64
.skip 0
TxTail2s:
    ldc        r6, 0
    // Two tail byte
    shl         r8, r8, 8
    or          r11, r11, r8
    shr         r8, r8, 8
    //outpw     res[TXD], r11, 8        // PID
    //outpw        res[TXD], r6, 16

    crc8         r7, r8, r8, r9
    crc8         r7, r8, r8, r9
    crc32        r7, r6, r9               // r5: 0
    not          r7, r7
    shr          r6, r7, 8

    shl        r7, r7, 24
    zext       r11, 24
    or         r11, r11, r7
XUD_IN_TxPid_TailS2:
    out     res[TXD], r11
//    outpw        res[TXD], r7, 16

XUD_IN_TxCrc_TailS2:
    outpw      res[TXD], r6, 8
    bu           DoneTail

.align 64
.skip 0
TxTail3s:
    ldc        r6, 0
	// Two tail byte
XUD_IN_TxPid_TailS3:
  outpw        res[TXD], r11, 8         // PID
  outpw        res[TXD], r8, 24
  crc8         r7, r8, r8, r9
  crc8         r7, r8, r8, r9
  crc8         r7, r8, r8, r9

  crc32        r7, r6, r9               // r5: 0
  not          r7, r7

XUD_IN_TxCrc_TailS3:
  outpw        res[TXD], r7, 16
  bu           DoneTail

