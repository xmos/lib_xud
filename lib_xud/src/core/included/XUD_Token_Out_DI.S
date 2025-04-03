// Copyright 2011-2025 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
// r10: EP number
// OUT Token Packet -----------------------------------------------------------------------------
#include "XUD_AlignmentDefines.h"

.align FUNCTION_ALIGNMENT
.skip 0
Pid_Out:
    #define  XTA_CRCADDRCHECK       xta_ep_Pid_Out_header
    #include "XUD_CrcAddrCheck.S"
    ldw        r3, r5[r10]                      // Load relevant EP pointer
    bf         r3, XUD_TokenOut_BufferFull
    ldw        r1, r3[3]                        // Load buffer from EP structure

OutReady:
    BLRF_u10    doRXData                        // Leaves r1: 0
RxRet2:
CheckEpTypeOut:
    {ldc       r1, 0;                ldw        r11, r3[5]}         // Load EP type
    bf         r11, StoreTailDataOut            // ISO endpoint
    bf         r6, NextTokenAfterOut            // Check for bad crc
DoOutNonIso:
    ldc        r11, USB_PIDn_ACK                // Data CRC good, EP not Iso, and EP not halted: Send Ack
xta_ep_DoOutNonIso_Ack:
    outpw      res[TXD], r11, 8
    syncr      res[TXD]

StoreTailDataOut:
    ldw        r11, r3[1]                       // Load EP chanend
xta_no_pauseG:
    out        res[r11], r4                     // Output datalength (words)
    stw        r1, r5[r10]                      // Clear ready (r1: 0)
xta_no_pauseH:
    {outt       res[r11], r8;   ldw    r6, sp[STACK_RXCRC_INIT]} // CRC16 init (out) - Needs reseting after an out & Send tail length
#if defined(__XS2A__)
    ldw         r1, sp[STACK_VTOK_PORT]
#endif
    #define  XTA_TOKENJMP_PID     xta_ep_Token_PID_RxRet2
    #define  XTA_TOKENJMP_EPCRC   xta_ep_Token_EPCRC_RxRet2
    #define  XTA_TOKENJMP_ID      C
    #include "XUD_TokenJmp.S"

// Various Error handling functions -------------------------------------------------------------------
.align FUNCTION_ALIGNMENT
Err_RxErr:                                      // RxError signal high during data packet receive:
    DUALENTSP_lu6 0
    clrsr     3
    clre
    ldw       r10, sp[STACK_RXE_PORT]           // Read out data from RxE port
  xta_no_pauseAA:
    in        r11, res[r10]
    eeu       res[r10]
    ldw       r10, sp[STACK_RXA_PORT]
  xta_ep_RxErr_RxALow:
    in        r11, res[r10]                     // Wait for rxa low and ignore packet (let transaction timout)
    setsr     2                                 // Re-enable thread interrupts
    bu        NextToken

XUD_TokenOut_BufferFull:
  ldw       r9, sp[STACK_RXA_PORT]
  setc      res[r9], XS1_SETC_RUN_CLRBUF
xta_ep_XUD_TokenOut_BufferFull:
  inpw        r4, res[r0], 8                    // Input PID of next packet.
                                                // TODO catch case where PID is not DATA

XUD_TokenOut_WaitForPacketEnd:                  // Wait for end of data then send NAK
xta_ep_XUD_TokenOut_WaitForPacketEnd:
  in        r11, res[r9]

#ifndef XUD_NAK_ISO_OUT
  ldw       r4, sp[STACK_EPTYPES_OUT]           // Load ep type table
  ldw       r4, r4[r10]                         // load EP type
  bf        r4, PrimaryBufferFull_NoNak
#endif

  // Load handshake (ACK or STALL)
XUD_TokenOut_Handshake:
  ldaw      r6, dp[epAddr]
  ldw       r6, r6[r10]
  ldw       r11, r6[10]
xta_ep_XUD_TokenOut_BufferFull_Nak:
  outpw     res[TXD], r11, 8
  syncr     res[TXD]

PrimaryBufferFull_NoNak:
  setc      res[RXD], XS1_SETC_RUN_CLRBUF
  bu        NextToken
