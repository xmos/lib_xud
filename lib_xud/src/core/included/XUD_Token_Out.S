// Copyright 2011-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
// r10: EP number
// OUT Token Packet -----------------------------------------------------------------------------
// Ports
#define RXD r0
#define TXD r2

.align 4
.skip 0
//.cc_top Pid_Out.func, Pid_Out
Pid_Out:
#ifdef ARCH_L
    inpw       r10, res[RXD], 8;                // Read EP Number */
    shr        r10, r10, 24;                    // Shift off junk */

    in         r4, res[r1];
    bt         r4, InvalidToken;                // If VALID_TOKEN not high, ignore token */
#else
    // ARCH_G
    #include "XUD_G_Crc.S"
#endif
    ldw        r3, r5[r10]                      // Load relevant EP pointer
    bf         r3, XUD_TokenOut_BufferFull
    ldw        r1, r3[3]                        // Load buffer from EP structure

CheckEpTypeOut:
    ldw        r11, r3[5]                       // Load EP type
    bt         r11, DoOutNonIso                 // ISO endpoint

OutReady:
    bl         doRXData
    clre
    ldc        r11, 0
    stw        r11, r5[r10]                     // Clear ready after receiving packet - avoids EP getting stuck in not-ready state if interrupted

InformEP_Iso:                                   // Iso EP - no handshake
    ldw        r11, r3[1]                       // Load EP chanend
    out        res[r11], r4                     // Output datalength (words)
    outt       res[r11], r8                     // Send tail length

    ldc        r6, 0x3334                       // CRC16 init (out) - Needs reseting after an out
#ifndef ARCH_G
    ldw        r1, sp[STACK_FLAG0_PORT]
#endif
    //ldc        r4, XUD_MAX_NUM_EP_OUT           // This could be shaved if XUD_MAX_NUM_EP's < 12. Now use an LDAW to at 16.

//------------------------------------------------------------------------------------------------
#ifdef ARCH_L
    ldaw        r10, dp[PidJumpTable]
                                                // Original USB Token: | CRC | EP | ADDR | PID | junk
                                                // Received token is address and CRC checked.
                                                // We receive: | 0000 4-bit EP | 0000 4-bit PID |
XUD_TokenRx_Pid_:
    inpw       r11, res[RXD], 8                 // Read 8 bit PID
    shr        r11, r11, 24                     // Shift off junk

    ldw        r10, r10[r11]                    // Load relevant branch address

BranchOnTokenPid_:
.xtabranch  Pid_Out, Pid_Sof, Pid_In, Pid_Setup, Pid_Sof_NoChan
    bau        r10
#else
    ldc         r4, 16

ReadToken_:
    inpw        r11, res[RXD], 8                       // Read 3 byte token from data port | CRC[5] | EP[4] | ADDR[7] | PID[8] | junk
    ldaw        r10, dp[PidJumpTable]
    setpsc      res[RXD], r4
    shr         r11, r11, 24

JumpOnPid_:
    ldw         r11, r10[r11]
    .xtabranch  Pid_Out, Pid_Sof, Pid_In, Pid_Setup
    bau         r11
#endif

.align 4
.skip 0
DoOutNonIso:
    bl         doRXData
    clre

    eq         r1, r6, r11                      // Check for good CRC16

doRXDataReturn_NonIso:
    bf         r1, NextTokenAfterOut            // Check for bad crc
    ldc        r11, USB_PIDn_ACK                    // Data CRC good and EP not Iso: Send Ack
    outpw      res[TXD], r11, 8
    syncr      res[TXD]

StoreTailDataOut:
    //shr        r8, r8, 3                      // r8: number of tail bits, convert to bytes
                                                // This is now done on the other side
    ldc        r11, 0
    stw        r11, r5[r10]                     // Clear ready
    ldw        r11, r3[1]                       // Load EP chanend

    out        res[r11], r4                     // Output datalength (words)
    outt       res[r11], r8                     // Send tail length

    bu        NextTokenAfterOut

// Various Error handling functions -------------------------------------------------------------------
Err_RxErr:                                      // RxError signal high during data packet receive:
    clrsr     3
    clre
    ldw       r10, sp[15]                       // Read out data from RxE port
    in        r11, res[r10]
    eeu       res[r10]
    ldw       r10, sp[10]
    in        r11, res[r10]                     // Wait for rxa low and ignore packet (let transaction timout)
    setsr     3                                 // Re-enable thread interrupts
    bu        NextToken

Err_EndpointProblem:
  // TODO:Endpoint in trouble (send STALL) or disabled (ignore?)...
  bu        NextToken

//Err_BadDataCrc:                               // Data packet received with bad crc: Ignore; wait for timeout (host will re-send)
  //bu        NextToken

Err_BadPidSeq:                                  // Bad pid sequencing (already ACKed good data).  Ignore data
  bu        NextToken

XUD_TokenOut_BufferFull:
  ldw       r9, dp[flag1_port]
  setc      res[r9], XS1_SETC_RUN_CLRBUF
  setc      res[r9], XS1_SETC_COND_NEQ
XUD_TokenOut_WaitForPacketEnd:                  // Wait for end of data then send NAK
  in        r11, res[r9]
  setc      res[r9], XS1_SETC_COND_EQ
  in        r11, res[r9]
                                                // TODO: Observe interpacket delay
#ifndef XUD_NAK_ISO_OUT
  ldw       r4, sp[(STACK_EXTEND+5)]            // Load ep type table
  ldw       r4, r4[r10]                         // load EP type
  bf        r4, PrimaryBufferFull_NoNak
#endif

  // LOAD HANDSHAKE PID or STALL
  ldaw       r5, dp[handshakeTable_OUT]         // Load handshake table
  ldw        r11, r5[r10]
  //ldc       r11, 0x5a
  outpw     res[TXD], r11, 8
  syncr     res[TXD]

PrimaryBufferFull_NoNak:
  //endin     r11, res[RXD]
  //in        r11, res[RXD]
  setc      res[RXD], XS1_SETC_RUN_CLRBUF
  bu        NextToken

// Timedout waiting for data after OUT... go back to waiting for tokens
OutDataTimeOut:
  //clre
  //bl	ERR_OutDataTimeout
  bu        NextToken



//.cc_bottom Pid_Out.func
