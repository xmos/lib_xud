// Copyright 2011-2022 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

// XUD_IoLoop.S
// Main USB interfacing loop
//
// XMOS Ltd
// Ross Owen
//
///////////////////////////////////////////////////////

#include <xs1.h>
#include "xud.h"
#include "XUD_USB_Defines.h"
#include "XUD_TimingDefines.h"
#include "XUD_AlignmentDefines.h"

.section        .cp.const4,"aMc",@progbits,4
.cc_top suspendTimeout.data
.align 4
suspendTimeout:
.long  SUSPEND_TIMEOUT_ticks
.cc_bottom suspendTimeout.data
.text

.section        .cp.const4,"aMc",@progbits,4
.cc_top suspend_t_wtwrsths.data
.align 4
suspend_t_wtwrsths:
.long SUSPEND_T_WTWRSTHS_ticks
.cc_bottom suspend_t_wtwrsths.data
.text


#define STACK_EXTEND 32

// Stack frame:
// 0
// 1..7:             : Reg save
// 8                 : Unused
#define STACK_OUT_TIMER (9)                 // Used for out data timeout
#define STACK_RXA_PORT (10)                 // RXA_port
// 11                : Unused
// 12                : Unused
#define STACK_SUSPEND_TIMEOUT   (13)
#define STACK_SUSPEND_TIMER     (14)
#define STACK_RXE_PORT          (15)
#define STACK_RXCRC_TAIL0       (16)
#define STACK_RXCRC_TAIL1       (17)
#define STACK_RXCRC_TAIL2       (18)
#define STACK_RXCRC_TAIL3       (19)
#define STACK_TXCRC_INIT        (20)
#define STACK_RXCRC_INIT        (21)
#define STACK_PIDJUMPTABLE      (22)
#define STACK_PIDJUMPTABLE_RXDATA (23)
#define STACK_CRC5TABLE_ADDR      (24)

// Params
#define STACK_VTOK_PORT     (STACK_EXTEND + 1)
#define STACK_EPTYPES_OUT   (STACK_EXTEND + 2)   // STACK_EXTEND + 6  : EP Type table (out)
#define STACK_EPTYPES_IN    (STACK_EXTEND + 3)   // EP Type table (in)
#define STACK_EPCHANS       (STACK_EXTEND + 4)
#define SP_EPCOUNT          (STACK_EXTEND + 5)
#define STACK_SOFCHAN       (STACK_EXTEND + 6)

#ifndef XUD_TEST_MODE_SUPPORT_DISABLED
//////////////////////////////////////////////////////////////////////////
// void UsbTestModeHandler()
// Interrupt handler for entering USB Test mode
// ASM level for low-level interrupt handling.
.globl UsbTestModeHandler_asm.nstackwords
.linkset UsbTestModeHandler_asm.nstackwords, 0
.globl UsbTestModeHandler_asm
.type UsbTestModeHandler_asm, @function
.text
.cc_top UsbTestModeHandler_asm.func, UsbTestModeHandler_asm
.issue_mode single
.align FUNCTION_ALIGNMENT
UsbTestModeHandler_asm:
    ENTSP_lu6   0
	clrsr       0x18
	clrsr       0x2
	clre                                           // clear all events
	get         r11, ed
    chkct       res[r11], XS1_CT_END
	outct       res[r11], XS1_CT_END
    in          r0, res[r11]
    chkct       res[r11], XS1_CT_END
	outct       res[r11], XS1_CT_END
    bf          r0, Return                         // Special case for Exit
    bl          XUD_UsbTestModeHandler
    retsp       0
.cc_bottom UsbTestModeHandler_asm.func
#endif

/////////////////////////////////////////////////////////////////////////
// void ResetIntHandler()
// Interupt handler for reset/suspend timer
.globl ResetIntHandler.nstackwords
.linkset ResetIntHandler.nstackwords, 0
.globl ResetIntHandler
.type ResetIntHandler, @function
.text
.cc_top ResetIntHandler.func, ResetIntHandler
.issue_mode dual
.align FUNCTION_ALIGNMENT
ResetIntHandler:
    DUALENTSP_lu6   0
    clrsr   0x18                                   // Clear InInterrupt bit (and InKernel)
    clrsr   0x3									   // Clear thread events and interrupts

    get     r11, ed                                // Get timer resource ID
    setc    res[r11], XS1_SETC_IE_MODE_EVENT       // Set IE mode back to events

    clre                                           // Clear all events

    ldw     r10, dp[SavedSp]                       // Restore stack pointer
    set     sp, r10

    ldc        r0, 1                               // Load non-zero (zero is kill)
    bu         Return

.cc_bottom ResetIntHandler.func

/////////////////////////////////////////////////////////////////////////////////////////////////////////
//    void XUD_LLD_IoLoop(in port rxd_port, in port rxa_port, out port txd_port, in port rxe_port, in port flag0_port,
//    chanend c_out, chanend c_in, chanend c_con_io, chanend c_ctl_buf,
//    XUD_EpType epTypeTableOut[], XUD_EpType epTypeTableIn[], XUD_chan epChans[], epCount, c_sof) ;
.globl XUD_LLD_IoLoop.nstackwords
.globl XUD_LLD_IoLoop.maxthreads
.globl XUD_LLD_IoLoop.maxtimers
.globl XUD_LLD_IoLoop.maxchanends

.linkset XUD_LLD_IoLoop.nstackwords, STACK_EXTEND
.linkset XUD_LLD_IoLoop.maxchanends, 0
.linkset XUD_LLD_IoLoop.maxtimers, 2
.linkset XUD_LLD_IoLoop.maxthreads, 0

.globl XUD_LLD_IoLoop
.type XUD_LLD_IoLoop, @function
.text
.cc_top XUD_LLD_IoLoop.func, XUD_LLD_IoLoop

.issue_mode dual
// Note, included here so in same elimination blocks to avoid long jumps
#include "./included/XUD_Token_In_DI.S"
#include "./included/XUD_Token_Setup_DI.S"
#include "./included/XUD_Token_Out_DI.S"
#include "./included/XUD_RxData.S"
#include "./included/XUD_Token_Ping.S"
#include "./included/XUD_Token_SOF.S"

BadCrcAddr:
    // zext       r11, 8
    // ldc        r10, PIDn_SOF
    // eq         r11, r11, r10
    //ecallt      r11
    //bt          r11, Pid_Sof_NoChan                    // TODO we should really CRC SOFs
    ldw         r11, sp[STACK_RXA_PORT]

waitforRXALow0:
    in          r10, res[r11]
    bt          r10, waitforRXALow0
    setc        res[RXD], XS1_SETC_RUN_CLRBUF
    bu          Loop_BadPid

.align FUNCTION_ALIGNMENT
XUD_LLD_IoLoop:
    DUALENTSP_lu6  STACK_EXTEND
    stw         r4, sp[1]
    stw         r5, sp[2]
    stw         r6, sp[3]
    stw         r7, sp[4]
    stw         r8, sp[5]
    stw         r9, sp[6]
    stw         r10, sp[7]
PortsOnStack:                                   // Put ports on stack (loads therefore short insts)
    stw         r1, sp[STACK_RXA_PORT]
    stw         r3, sp[STACK_RXE_PORT]

SaveStackPointer:
    ldaw        r11, sp[0]
    stw         r11, dp[SavedSp]


    ldw         r11, cp[suspendTimeout]
    stw         r11, sp[STACK_SUSPEND_TIMEOUT]

ConfigRxDEventVector:                           // Configure event on RXD port for receiveing a handshake after Tx
    setc        res[RXD], XS1_SETC_IE_MODE_EVENT
    ldap        r11,  TxHandShakeReceived
    setv        res[RXD], r11

ConfigRxA:                                      // Configure a event on RXA going low, used during packet reception
    setc        res[RXA], XS1_SETC_COND_EQ
    setc        res[RXA], XS1_SETC_IE_MODE_EVENT
    ldc         r11, 0
    setd        res[RXA], r11
    ldap        r11, RxALow
    setv        res[RXA], r11
    eeu         res[RXA]

ConfigValidToken:
#ifdef __XS2A__
    ldw         r10, sp[STACK_VTOK_PORT]        // ValidToken is used for timing timeout period when expecting an ack after tx
#else
    ldw         r10, dp[rx_rdy]                 // TODO use from stack
#endif
    setc        res[r10], XS1_SETC_COND_NONE
    ldap        r11, TxHandshakeTimeOut
    setv        res[r10], r11

#ifndef XUD_TEST_MODE_SUPPORT_DISABLED
SetupUsbTestMode:
    // Enable test mode interrupt on Endpoint 0 chanends. IN + OUT
    ldaw         r9, dp[epChans0]
    ldw         r10, r9[0]                         // Load channel 0

    ldap        r11, UsbTestModeHandler_asm
    setc        res[r10], XS1_SETC_IE_MODE_INTERRUPT
    setv        res[r10], r11
    eeu         res[r10]

    ldc         r10, 16
    ldw         r10, r9[r10]                     // Load channel for EP 0 in

    setc        res[r10], XS1_SETC_IE_MODE_INTERRUPT
    setv        res[r10], r11
    eeu         res[r10]
#endif

CrcRxResidualsOnStack:
    ldc        r11, 0x7000
    stw        r11, sp[STACK_RXCRC_TAIL0]
    ldc        r11, 0x80be
    stw        r11, sp[STACK_RXCRC_TAIL1]
    ldc        r11, 0x3ffe
    stw        r11, sp[STACK_RXCRC_TAIL2]
    ldc        r11, 0x3ffe
    stw        r11, sp[STACK_RXCRC_TAIL3]

    ldc        r11, 0xf335                       // CRC16 init (in)
    stw        r11, sp[STACK_TXCRC_INIT]

    ldc        r11, 0x3334                      // CRC16 init (out)
    stw        r11, sp[STACK_RXCRC_INIT]

    ldw        r11, sp[STACK_EPCHANS]
    stw        r11, dp[chanArray]

ConfigSofJump:
    ldw        r11, sp[STACK_SOFCHAN]
    ldaw       r10, dp[PidJumpTable]
    bt         r11, ConfigSofJump_Done
    ldap       r11, Pid_Sof_NoChan
#ifdef __XS2A__
    stw        r11, r10[5]
#else
    ldc        r9, 0xa5
    stw        r11, r10[r9]
#endif
ConfigSofJump_Done:
    stw        r10, sp[STACK_PIDJUMPTABLE]

    ldaw       r10, dp[PidJumpTable_RxData]
    stw        r10, sp[STACK_PIDJUMPTABLE_RXDATA]

    ldaw       r10, dp[crc5Table_Addr]
    stw        r10, sp[STACK_CRC5TABLE_ADDR]


ConfigRxErrEventVector:
    setc       res[r3], XS1_SETC_COND_EQ
    setc       res[r3], XS1_SETC_IE_MODE_INTERRUPT
    ldap       r11, Err_RxErr
    setv       res[r3], r11
    ldc        r11, 1
    setd       res[r3], r11                 // Set event cond data to 1
    eeu        res[r3]

SetupSuspendResetTimer:
    getr       r10, XS1_RES_TYPE_TIMER
    ecallf     r10

    stw        r10, sp[STACK_SUSPEND_TIMER]

    ldap       r11, ResetIntHandler
    setv       res[r10], r11

    setc       res[r10], XS1_SETC_COND_NONE
    in         r11, res[r10]                    // Get current time
    ldw        r9, cp[suspendTimeout]
    add        r11, r11, r9
    setd       res[r10], r11
    setc       res[r10], XS1_SETC_COND_AFTER
    setc       res[r10], XS1_SETC_IE_MODE_INTERRUPT
    eeu        res[r10]                         // Enable events/interupts on resource

    setc       res[RXD], XS1_SETC_RUN_CLRBUF

    clre
    setsr      0x2                             // Enable thread interrupts
    bu         NextToken

// Main IO Loop
.align FUNCTION_ALIGNMENT
.skip 0
NextToken:
    ldc         r9, 0xa001                      // CRC16 poly, used in doRxData
    ldw         r5, sp[(STACK_EXTEND+4)]        // EP structures array - pointers to EP tables or 0

NextTokenAfterOut:
    ldc         r7, 0xf335                      // TX Crc init
    ldc         r6, 0x3334                      // CRC16 init (out) - Needs reseting after an out
#ifdef __XS2A__
    ldw         r1, sp[STACK_VTOK_PORT]
#endif

Loop_BadPid:
NextTokenAfterPing:
    setsr       1                               // Enable thread events

    #include "XUD_TokenJmp.S"

// Un-implemented PID list
Pid_Reserved:
Pid_Ack:
Pid_NYet:
Pid_Nyet:
Pid_Data2:
Pid_Split:
Pid_Nak:
Pid_Pre:
Pid_Stall:
Pid_MData:
Pid_Datam:
Pid_Data0:
Pid_Data1:
Pid_Bad:                                            // Bad PID received, ignore

XUD_InvalidToken:
    ldw        r10, sp[STACK_RXA_PORT]              // Load RxA Port ID (r1)
XUD_InvalidTok_waitforRXALow:
    in         r11, res[r10]
    bt         r11, XUD_InvalidTok_waitforRXALow
    setc       res[RXD], XS1_SETC_RUN_CLRBUF
    bu         Loop_BadPid                          // Invalid token received Ignore unknown toks

.align FUNCTION_ALIGNMENT
Return:
    clre
    ldw        r11, sp[STACK_SUSPEND_TIMER]         // Free suspend/reset timer
    edu        res[r11]
    freer      res[r11]

    ldw        r11, sp[STACK_RXE_PORT]              // Put RxE IE mode back to events..
    setc       res[r11], XS1_SETC_COND_NONE
    edu        res[r11]
    setc       res[r11], XS1_SETC_IE_MODE_EVENT

    ldw        r11, sp[STACK_RXA_PORT]
    edu        res[r11]

    ldw        r4, sp[1]                            // Register restore
    ldw        r5, sp[2]
    ldw        r6, sp[3]
    ldw        r7, sp[4]
    ldw        r8, sp[5]
    ldw        r9, sp[6]
    ldw        r10, sp[7]
    retsp     STACK_EXTEND


.cc_bottom XUD_LLD_IoLoop.func


// Tables of tables...
#include "./included/XUD_PidJumpTable.S"
#include "./included/XUD_PidJumpTable_RxData.S"

