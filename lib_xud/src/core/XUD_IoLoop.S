// Copyright 2011-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

// XUD_LLD_IoLoop.S
// Main USB interfacing loop
//
// XMOS Ltd
// Ross Owen
//
///////////////////////////////////////////////////////

#include <xs1.h>
#include "xud.h"
#include "XUD_USB_Defines.h"
#include "XUD_UIFM_Defines.h"
#include "XUD_TimingDefines.h"

.section        .cp.const4,"aMc",@progbits,4
.cc_top suspendTimeout.data
.align 4
suspendTimeout:
.long  SUSPEND_TIMEOUT
.cc_bottom suspendTimeout.data
.text

.section        .cp.const4,"aMc",@progbits,4
.cc_top suspend_t_wtwrsths.data
.align 4
suspend_t_wtwrsths:
.long SUSPEND_T_WTWRSTHS
.cc_bottom suspend_t_wtwrsths.data
.text


#define STACK_EXTEND 32

// Stack frame:
// 0
// 1..7:             : Reg save
// 8                 : TX handshake timer
// 9                 : Out timer
#define STACK_FLAG1_PORT (STACK_EXTEND-12)// 10                : RXA_port
#define STACK_FLAG0_PORT (STACK_EXTEND-11)// 11                : Valid token port
// 12                : ?
// 13                : Suspend timeout
// 14                : Suspend/Reset timer
// 15                : RxError port (flag 2)

#define STACK_PID_JUMP_TABLE (STACK_EXTEND-3)

// Params
// STACK_EXTEND + 1  : Flag0_port
// STACK_EXTEND + 2  : reg_read_port
// STACK_EXTEND + 3  : reg_write_port
// STACK_EXTEND + 4  : 0
// STACK_EXTEND + 5  : c_ctl_buf

#define SP_EPTYPES_OUT  (STACK_EXTEND +6)    // STACK_EXTEND + 6  : EP Type table (out)
#define SP_EPTYPES_IN   (STACK_EXTEND + 7)   // EP Type table (in)
#define SP_EPCHANS      (STACK_EXTEND + 7)
#define SP_EPCOUNT      (STACK_EXTEND + 9)
#define SP_REGREAD      (STACK_EXTEND + 10)
#define SP_REGWRITE     (STACK_EXTEND + 11)






#ifndef XUD_TEST_MODE_SUPPORT_DISABLED
//////////////////////////////////////////////////////////////////////////
// void UsbTestModeHandler()
// Interrupt handler for entering USB Test mode
// ASM level for low-level interrupt handling.
.globl UsbTestModeHandler_asm.nstackwords
.linkset UsbTestModeHandler_asm.nstackwords, 0
.globl UsbTestModeHandler_asm
.text
.cc_top UsbTestModeHandler_asm.func, UsbTestModeHandler_asm
UsbTestModeHandler_asm:
	clrsr       0x18
	clrsr       0x2
	clre // clear all events
	get         r11, ed
    chkct       res[r11], XS1_CT_END
	outct       res[r11], XS1_CT_END
    in          r0, res[r11]
    chkct       res[r11], XS1_CT_END
	outct       res[r11], XS1_CT_END
//	in r0, res[r11]
	retsp       0
.cc_bottom UsbTestModeHandler_asm.func
#endif


.globl XUD_UsbTestSE0.nstackwords
.linkset XUD_UsbTestSE0.nstackwords, 0
.globl XUD_UsbTestSE0
.text
.cc_top XUD_UsbTestSE0.func, XUD_UsbTestSE0
XUD_UsbTestSE0:
    ldw         r0, dp[p_usb_rxd]                           // Load RXD port
    ldw         r1, dp[flag0_port]                          // Valid token port
    ldw         r2, dp[p_usb_txd]                           // Load TXD port
    ldw         r3, dp[flag1_port]                          // Load RXA port

XUD_UsbTestSE0_loop:
    inpw        r11, res[r0], 8                             // Read 8 bit PID
    shr         r11, r11, 24                                // shift off junk

    inpw        r9, res[r0], 8                              // Read EP Number (dont care)

    in          r9, res[r1]
    bt          r9, InvalidTestToken                        // If VALID_TOKEN high, ignore token

    eq          r10, r11, USB_PID_IN
    bf          r10, XUD_UsbTestSE0_loop

    nop
    nop
    nop
    nop
    nop

    ldc         r11, USB_PIDn_NAK
	outpw       res[r2], r11, 8
	syncr       res[r2]
    bu          XUD_UsbTestSE0_loop

InvalidTestToken:
    in          r11, res[r3]
    bt          r11, InvalidTestToken
    setc        res[r0], XS1_SETC_RUN_CLRBUF                // Clear RXD port
    bu          XUD_UsbTestSE0_loop


// End of code for Test_SE0_NAK
.cc_bottom XUD_UsbTestSE0.func


/////////////////////////////////////////////////////////////////////////
// void ResetIntHandler()
// Interupt handler for reset/suspend timer
.globl ResetIntHandler.nstackwords
.linkset ResetIntHandler.nstackwords, 0
.globl ResetIntHandler
.text
.cc_top ResetIntHandler.func, ResetIntHandler
ResetIntHandler:
    clrsr   0x18                                // Clear InInterrupt bit (and InKernel)
    clrsr   0x2

    get     r11, ed                             // Get timer resource ID
    setc    res[r11], XS1_SETC_IE_MODE_EVENT    // Set IE mode back to events

    clre                                        // Clear all events

    ldw     r10, dp[SavedSp]                    // Restore stack pointer
    set     sp, r10

#if 0 // RxError Interrupts Disabled
    ldw     r11, sp[15]                         // Put RxE back to events..
    setc    res[r11], XS1_SETC_IE_MODE_EVENT    // Set IE mode back to events
#endif


ResetDetect:
    ldc        r0, 0                            // Return 0 for reset
    bu         writesuspendvar


SuspendDetect:
    ldc        r0, 1

writesuspendvar:
    //stw         r0, dp[suspend]
    bu         Return                        // Return 1 for suspend

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
.cc_top XUD_LLD_IoLoop.func, XUD_LLD_IoLoop
.text

// Note, included here so in same elimination blocks to avoid long jumps
#include "./included/XUD_Token_Out.S"
#include "./included/XUD_Token_Ping.S"
#include "./included/XUD_Token_In.S"
#include "./included/XUD_Token_Setup.S"
#include "./included/XUD_Token_SOF.S"

.align 4
XUD_LLD_IoLoop:
#if defined(__XS2A__)
.issue_mode single
    ENTSP_lu6  STACK_EXTEND
#else
    entsp      STACK_EXTEND
#endif
    stw         r4, sp[1]
    stw         r5, sp[2]
    stw         r6, sp[3]
    stw         r7, sp[4]
    stw         r8, sp[5]
    stw         r9, sp[6]
    stw         r10, sp[7]

SaveStackPointer:
    ldaw        r11, sp[0]
    stw         r11, dp[SavedSp]


    ldw         r11, cp[suspendTimeout]
    stw         r11, sp[13]

ConfigRxDEventVector:                         // Configure events
    setc        res[RXD], XS1_SETC_IE_MODE_EVENT
    ldap         r11,  TxHandShakeReceived
    setv         res[RXD], r11



ConfigRxA:
    setc       res[RXA], XS1_SETC_COND_EQ
    setc       res[RXA], XS1_SETC_IE_MODE_EVENT
    ldc        r11, 0
    setd       res[r1], r11
    ldap       r11, RxALow
    setv       res[r1], r11
    eeu        res[RXA]

ConfigValidToken:
    ldw        r10, dp[flag0_port]                    // Valid token port
    setc       res[r10], XS1_SETC_COND_NONE
    ldap       r11, TxHandshakeTimeOut                // ValidToken is used for timing timeout period when expecting an ack after tx
    setv       res[r10], r11
#if 0
    // Port counter used instead
TxHandShakeTimer:                                     // Used for timeout waiting for handshake after tx
    getr       r10, XS1_RES_TYPE_TIMER
    ecallf     r10

    ldap       r11, TxHandshakeTimeOut
    setv       res[r10], r11
    setc       res[r10], XS1_SETC_COND_AFTER

    stw        r10, sp[8]                             // Save timer resource ID to the stack
#endif

SetupOutTimer:
    getr       r10, XS1_RES_TYPE_TIMER
    ecallf     r10

    ldap       r11, OutDataTimeOut
    setv       res[r10], r11
    setc       res[r10], XS1_SETC_COND_AFTER

    stw        r10, sp[9]

#ifndef XUD_TEST_MODE_SUPPORT_DISABLED
SetupUsbTestMode:
    // Enable test mode interrupt on Endpoint 0 chanends. IN + OUT
    ldaw         r9, dp[epChans0]
    ldw         r10, r9[0]                         // Load channel 0

    ldap        r11, XUD_UsbTestModeHandler
    setc        res[r10], XS1_SETC_IE_MODE_INTERRUPT
    setv        res[r10], r11
    eeu         res[r10]

    ldc         r10, 16
    ldw         r10, r9[r10]                     // Load channel for EP 0 in

    setc        res[r10], XS1_SETC_IE_MODE_INTERRUPT
    setv        res[r10], r11
    eeu         res[r10]
#endif

PortsOnStack:                                   // Put ports on stack (loads therefore short insts)
    ldw        r11, dp[flag1_port]              // RxA
    stw        r11, sp[10]
    ldw        r11, dp[flag0_port]              // Valid token port
    stw        r11, sp[STACK_FLAG0_PORT]
    ldc        r11, 0x3ffe
    stw        r11, sp[12]

    ldw        r11, sp[(STACK_EXTEND+7)]
    stw        r11, dp[chanArray]

ConfigSofJump:
    ldw        r11, sp[(STACK_EXTEND+9)]
    bt         r11, ConfigSofJump_Done
    ldap       r11, Pid_Sof_NoChan
    ldaw       r10, dp[PidJumpTable]
#ifdef ARCH_L
    stw        r11, r10[5]
#else
    ldc        r9, 0xa5
    stw        r11, r10[r9]
#endif
ConfigSofJump_Done:

ConfigRxErrEventVector:
    stw        r3, sp[15]                   // Store flag port to stack
#if 0 // RxError Interrupts Disabled
    setc       res[r3], XS1_SETC_COND_EQ
    setc       res[r3], XS1_SETC_IE_MODE_INTERRUPT
    ldap       r11, Err_RxErr
    setv       res[r3], r11
    ldc        r11, 1
    setd       res[r3], r11                 // Set event cond data to 1
    eeu        res[r3]
#endif


SetupSuspendResetTimer:
    getr       r10, XS1_RES_TYPE_TIMER
    ecallf     r10

    stw        r10, sp[14]

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
.align 4
.skip 0
NextToken:
    ldc         r9, 0xa001                      // CRC16 poly, used in doRxData
    ldw         r5, sp[(STACK_EXTEND+7)]        // EP structures array - pointers to EP tables or 0
    ldc         r7, 0xf335                      // TX Crc init

NextTokenAfterOut:
    ldc         r6, 0x3334                      // CRC16 init (out) - Needs reseting after an out
#ifndef ARCH_G
    ldw         r1, sp[STACK_FLAG0_PORT]
#else
    //ldaw        r1, dp[crc5Table_Addr]
#endif
NextTokenAfterInNak:
Loop_BadPid:
    //ldc         r4, XUD_MAX_NUM_EP_OUT        // Number of OUT endpoints
NextTokenAfterPing:
    setsr       1                               // Enable thread events



//------------------------------------------------------------------------------------------------
#ifdef ARCH_L
    //ldw         r1, sp[11]                    // Load Valid Token port
    ldaw        r10, dp[PidJumpTable]           // TODO Could load from sp here
                                                // Original USB Token: | CRC | EP | ADDR | PID | junk
                                                // Received token is address and CRC checked.
                                                // We receive: | 0000 4-bit EP | 0000 4-bit PID |
XUD_TokenRx_Pid:
    inpw       r11, res[RXD], 8                 // Read 8 bit PID
    shr        r11, r11, 24                     // Shift off junk

    ldw        r10, r10[r11]                    // Load relevant branch address

#if 1
BranchOnTokenPid:
.xtabranch  Pid_Out, Pid_Sof, Pid_In, Pid_Setup, Pid_Sof_NoChan

    bau        r10

#else
XUD_TokenRx_Ep:
    inpw      r10, res[RXD], 8                  // Read EP Number
    shr       r10, r10, 24                      // Shift off junk

CheckValidToken:
    in         r1, res[r1]
    bt         r1, InvalidToken                 // If VALID_TOKEN not high, ignore token
                                                // REMEMBER VALID TOKEN NOW INVERTED!

BranchOnTokenPid:
.xtabranch  Pid_Out, Pid_Sof, Pid_In, Pid_Setup, Pid_Sof_NoChan
    bau         r11                             // Branch on PID to relevant token handing code
                                                // (e.g. in utmi_out.S etc). When done branchs back to NextToken
#endif
#else // ARCH_G
    ldc         r4, 16

ReadToken:
    inpw        r11, res[RXD], 8                // Read 3 byte token from data port | CRC[5] | EP[4] | ADDR[7] | PID[8] | junk
    ldaw        r10, dp[PidJumpTable]
    setpsc      res[RXD], r4
    shr         r11, r11, 24

JumpOnPid:
    ldw         r11, r10[r11]
.xtabranch  Pid_Out, Pid_Sof, Pid_In, Pid_Setup
    bau         r11

BadCrcAddr:
   // zext        r11, 8
   // ldc         r10, PIDn_SOF
   // eq          r11, r11, r10
    //ecallt     r11
    //bt          r11, Pid_Sof_NoChan                    // TODO we should really CRC SOFs

    ldw         r11, sp[10]
waitforRXALow0:
    in          r10, res[r11]
    bt          r10, waitforRXALow0
    setc        res[RXD], XS1_SETC_RUN_CLRBUF
    bu          Loop_BadPid

#endif


// Un-implemented PID list
Pid_Reserved:                                  // Should never get here
//Pid_Out:
Pid_Ack:
//Pid_Ping:
//Pid_Sof:                                      // Should never get here: (G4) hardware swallows SOF
Pid_NYet:
Pid_Nyet:
Pid_Data2:
Pid_Split:
//Pid_In:
Pid_Nak:
Pid_Pre:
//Pid_Setup:
Pid_Stall:
Pid_MData:
Pid_Datam:
Pid_Data0:
Pid_Data1:
Pid_Bad:                                        // Bad PID received, ignore

InvalidToken:
XUD_InvalidToken:
    ldw        r10, sp[10]           		    // Load RxA Port ID (r1)
waitforRXALow:
XUD_InvalidTok_waitforRXALow:
    in         r11, res[r10]
    bt         r11, waitforRXALow
    setc       res[RXD], XS1_SETC_RUN_CLRBUF
    bu         Loop_BadPid                      // Invalid token received Ignore unknown toks


.align 4
Return:
    //ldw        r11, sp[8]                       # Free timers
    //freer      res[r11]
    ldw        r11, sp[9]
    freer      res[r11]
    ldw        r11, sp[14]
    freer      res[r11]

    ldw        r4, sp[1]                        # Register restore
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
