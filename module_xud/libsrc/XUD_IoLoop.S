
// XUD_LLD_IoLoop.S
// Main USB interfacing loop
//
// XMOS Ltd
// Ross Owen
//
///////////////////////////////////////////////////////

#include <xs1.h>
#include "XUD_USB_Defines.h"
#include "XUD_internal_defines.h"
#include "XUD_UIFM_Defines.h"


#define SUSPEND_TIMEOUT_us   3000 // 3ms
#define SUSPEND_TIMEOUT           (SUSPEND_TIMEOUT_us * XCORE_FREQ_MHz / (REF_CLK_DIVIDER+1))

.section        .cp.const4,"aMc",@progbits,4
.align  4
suspendTimeout:
.long  SUSPEND_TIMEOUT
.text

.section        .cp.const4,"aMc",@progbits,4
.align  4
suspend_t_wtwrsths:
.long SUSPEND_T_WTWRSTHS
.text


.extern SetupChannelVectors
.globl SetupChannelVectors.nstackwords
.globl SetupChannelVectors.maxthreads
.globl SetupChannelVectors.maxtimers
.globl SetupChannelVectors.maxchanends

.linkset SetupChannelVectors.nstackwords, 16
.linkset SetupChannelVectors.maxchanends, 0
.linkset SetupChannelVectors.maxtimers, 0
.linkset SetupChannelVectors.maxthreads, 0

.globl SetupChannelVectors
.cc_top SetupChannelVectors.func, SetupChannelVectors
.text 


// void SetupChannelVectors(chans[], CountOut, CountIn);

.align 4
.skip 0
SetupChannelVectors:
    entsp 16
    stw         r5, sp[1]
    stw         r6, sp[2]
    stw         r2, sp[3]
        
EnableEpChanEvents_Out2:
    //mov           r3, r1
    ldc         r3, XUD_MAX_NUM_EP_OUT

OutEventLoop:                                      // Set event vectors for all channels 
    bf          r1, InEventLoop                
    sub         r1, r1, 1
    ldw         r5, r0[r1]
    ldap        r11, OutReady
    setv        res[r5], r11
    bu          OutEventLoop

InEventLoop:
    bf          r2, InEventLoopEnd
    sub         r2, r2, 1
    add         r6, r2, r3                    // Add in channel offset
    ldw         r5, r0[r6]
    ldap        r11, InReady
    setv        res[r5], r11
    bu          InEventLoop

InEventLoopEnd:

    // Some applications may want to override the
    // handling of some channels
    mov         r1, r3
    ldw         r2, sp[2]
    bl          SetupChannelVectorsOverride

    ldw         r5, sp[1]
    ldw         r6, sp[2]
    retsp       16

.cc_bottom SetupChannelVectors.func


#define STACK_EXTEND 16

#include "./included/XUD_Token_Out.S"
#include "./included/XUD_Token_Ping.S"
#include "./included/XUD_Token_In.S"
#include "./included/XUD_Token_Setup.S"
#include "./included/XUD_Token_SOF.S"


// Stack frame:
// 0
// 1..7:             : Reg save
// 8                 : TX handshake timer
// 9                 : Out timer
// 10                : RXA_port
// 11                : Valid token port
// 12                : ?
// 13                : Suspend timeout
// 14                : Suspend/Reset timer


// Params
// STACK_EXTEND + 1  : Flag0_port
// STACK_EXTEND + 2  : reg_read_port
// STACK_EXTEND + 3  : reg_write_port
// STACK_EXTEND + 4  : 0
// STACK_EXTEND + 5  : c_ctl_buf
// STACK_EXTEND + 6  : EP Type table (out)
#define SP_EPTYPES_IN (STACK_EXTEND + 7)  //: EP Type table (in)
#define SP_EPCHANS    (STACK_EXTEND + 7)
#define SP_EPCOUNT    (STACK_EXTEND + 9)
#define SP_REGREAD    (STACK_EXTEND + 10)
#define SP_REGWRITE   (STACK_EXTEND + 11)

//////////////////////////////////////////////////////////////////////////
// void UsbTestModeHandler()
// Interrupt handler for entering USB Test mode
// ASM level for low level interrupt handling.
.extern UsbTestModeHandler_asm
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


.extern 		 XUD_UsbTestSE0
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
    bf          r9, InvalidTestToken                        // If VALID_TOKEN not high, ignore token

    eq          r10, r11, PID_IN 
    bf          r10, XUD_UsbTestSE0_loop

    nop 
    nop
    nop
    nop
    nop

    ldc         r11, PIDn_NAK			               	
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
.extern ResetIntHandler
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
    //setc    res[r11], XS1_SETC_IE_MODE_INTERRUPT  // Set IE mode back to events

    ldw     r10, dp[SavedSp]                    // Restore stack pointer
    set     sp, r10

#if 0
    // Reset flags
    ldc     r10, UIFM_CMD_WRITE                 
    ldc     r9, UIFM_REG_FLAGS
    or      r10, r10, r9
    ldw     r9, sp[19]                          // Reg write port
    out     res[r9], r10
    ldc     r10, 0
    out     res[r9], r10

    // Put in FS mode s(XcvrSelect and TermSelect = 1)
    ldc     r10, UIFM_CMD_WRITE                 
    ldc     r9, UIFM_REG_PHYCON
    or      r10, r10, r9
    ldw     r9, sp[19]
    out     res[r9], r10
    ldc     r10, 0x7
    out     res[r9], r10

    // Delay by SUSPEND_WTWRSTHS
    setc    res[r11], XS1_SETC_COND_NONE     // Read current time
    in      r10, res[r11]
    ldw     r9, cp[suspend_t_wtwrsths]
    add     r10, r10, r9
    setd    res[r11], r10   
    setc    res[r11], XS1_SETC_COND_AFTER    
    in      r10, res[r11]

    // Check for J state. If so the initial SE0 was due to suspend (remain in HS) else was reset 
    ldc     r10, UIFM_CMD_READ                 
    ldc     r9, UIFM_REG_FLAGS
    or      r10, r10, r9
    ldw     r9, sp[19]                       // Reg Write Port
    out     res[r9], r10
    ldw     r9, sp[18]                       // Reg Read Port
    in      r10, res[r9]                    

    // Check for suspend (full speed J)       
    ldc        r9, UIFM_FLAGS_FS_J          // HS K / FS J bit
    and        r9, r10, r9
    bt         r9, SuspendDetect

#endif
ResetDetect:
    ldc        r0, 0                         // Return 0 for reset
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
//    XUD_EpType epTypeTableOut[], XUD_EpType epTypeTableIn[], XUD_chan epChans[], epCount, c_sof, c_usb_testmode) ;
.extern XUD_LLD_IoLoop
.globl XUD_LLD_IoLoop.nstackwords
.globl XUD_LLD_IoLoop.maxthreads
.globl XUD_LLD_IoLoop.maxtimers
.globl XUD_LLD_IoLoop.maxchanends

.linkset XUD_LLD_IoLoop.nstackwords, STACK_EXTEND
.linkset XUD_LLD_IoLoop.maxchanends, 0
.linkset XUD_LLD_IoLoop.maxtimers, 3
.linkset XUD_LLD_IoLoop.maxthreads, 0

.globl XUD_LLD_IoLoop
.cc_top XUD_LLD_IoLoop.func, XUD_LLD_IoLoop
.text 

.align 4
.skip 0
XUD_LLD_IoLoop:
utmi_io:
    entsp       STACK_EXTEND        
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


    ldw           r11, cp[suspendTimeout]         
    stw           r11, sp[13]
        
    //ldc           r11, 0
    //stw           r11, sp[15]

//SetControlChannelEvent:                       // Currently we don't need this interrupt handler in XUD_lite
    //ldap        r11, ConChanIntHandler
    //ldw         r10, sp[(STACK_EXTEND + 4)]
    //setv        res[r10], r11
    //setc        res[r10], XS1_SETC_IE_MODE_INTERRUPT 
    //eeu         res[r10]                      // Enable events/interupts on resource 
    //setsr       0x2                           // Enable thread interupts on kill channel


#if 0                                           // To speed up reset this is now only done once
EnableEpChanEvents_Out:
    ldw         r9, sp[SP_EPCOUNT]              // Load passed EP count from stack
    ldw         r7, sp[SP_EPCOUNT]
    ldw         r8, sp[SP_EPCHANS]              // Load EP Channels array

EventLoop:                                      // Set event vectors for all channels 
    bf          r9, EventLoopEnd                
    sub         r9, r9, 1
    ldw         r5, r8[r9]
    ldap        r11, OutReady
    setv        res[r5], r11

    add         r6, r7, r9                    // Add in channel offset
    ldw         r5, r8[r6]
    ldap        r11, InReady
    setv        res[r5], r11
    bu          EventLoop

EventLoopEnd:
#endif     
        

ConfigRxDEventVector:                         // Configure events
    setc        res[RXD], XS1_SETC_IE_MODE_EVENT  
    ldap        r11, NextRxWord
    setv        res[RXD], r11
    eeu         res[RXD]

ConfigRxErrEventVector:
    //setc       res[RXE], XS1_SETC_IE_MODE_EVENT 
    //ldap       r11, Err_RxErr
    //setv       res[RXE], r11
    //stw        RXE, sp[13]                    // Store flag port to stack

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

TxHandShakeTimer:                                     // Used for timeout waiting for handshake after tx
    getr       r10, XS1_RES_TYPE_TIMER
    ecallf     r10

    ldap       r11, TxHandshakeTimeOut 
    setv       res[r10], r11
    setc       res[r10], XS1_SETC_COND_AFTER

    stw        r10, sp[8]                             // Save timer resource ID to the stack

SetupOutTimer:
    getr       r10, XS1_RES_TYPE_TIMER
    ecallf     r10

    ldap       r11, OutDataTimeOut
    setv       res[r10], r11
    setc       res[r10], XS1_SETC_COND_AFTER

    stw        r10, sp[9]

SetupUsbTestMode:
	// sp[10] should be c_usb_testmode
	ldw         r10, sp[(10 + STACK_EXTEND)]
    bf          r10, PortsOnStack               // Check for NULL
    ldap        r11, XUD_UsbTestModeHandler
    setc        res[r10], XS1_SETC_IE_MODE_INTERRUPT 
    setv        res[r10], r11
    eeu         res[r10]

PortsOnStack:                                   // Put ports on stack (loads therefore short insts)
    ldw        r11, dp[flag1_port]              // RxA
    stw        r11, sp[10]
    ldw        r11, dp[flag0_port]              // Valid token port
    stw        r11, sp[11]
    //ldw        r11, dp[flag2_port]              // 
    //stw        r11, sp[15]

    //ldc         r11, 0x0070                          
    ldc        r11, 0x3ffe
    stw         r11, sp[12]

    ldw         r11, sp[(STACK_EXTEND+7)]
    stw         r11, dp[chanArray]

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
    setsr       0x2                             // Enable thread interrupts

    setc       res[RXD], XS1_SETC_RUN_CLRBUF
    ldw         r1, sp[11]                            // Load Valid Token port
    //ldc         r3, 0 
                                          
    bu         Loop

// Main IO Loop
.align 4
.skip 0
Loop:
NextToken:
PreLoads:
    ldc         r9, 0xa001                      // CRC16 poly, used in doRxData              
    ldw         r5, sp[(STACK_EXTEND+7)]        // EP structures array - pointers to EP tables or 0

NextTokenAfterOut:
    ldc         r7, 0xf335                      // TX Crc init 

NextTokenAfterIn:
    ldc         r6, 0x3334                      // CRC16 init (out) - Needs reseting after an out
    ldw         r1, dp[flag0_port]           		             
NextTokenAfterInNak:
Loop_BadPid: 
    //ldw         r4, //sp[(STACK_EXTEND+8)]        // Number of out Endpoints
    ldc         r4, XUD_MAX_NUM_EP_OUT
NextTokenAfterPing:
    clre
    setsr       1                               // Enable thread events



//------------------------------------------------------------------------------------------------
#ifdef ARCH_L
    //ldw         r1, sp[11]                          // Load Valid Token port
    ldaw        r10, dp[PidJumpTable]                 // TODO Could load from sp here
                                                      // Original USB Token: | CRC | EP | ADDR | PID | junk 
                                                      // Received token is address and CRC checked.
                                                      // We receive: | 0000 4-bit EP | 0000 4-bit PID |
XUD_TokenRx_Pid: 
    inpw       r11, res[RXD], 8                       // Read 8 bit PID
    shr        r11, r11, 24                           // Shift off junk 
    
    ldw        r10, r10[r11]                          // Load relevant branch address

#if 1        
BranchOnTokenPid:
.xtabranch  Pid_Out, Pid_Sof, Pid_In, Pid_Setup, Pid_Sof_NoChan

    bau        r10
     
#else  
XUD_TokenRx_Ep:
    inpw      r10, res[RXD], 8                        // Read EP Number 
    shr       r10, r10, 24                            // Shift off junk

CheckValidToken:
    in         r1, res[r1]
    bf         r1, InvalidToken                       // If VALID_TOKEN not high, ignore token
 
BranchOnTokenPid:
.xtabranch  Pid_Out, Pid_Sof, Pid_In, Pid_Setup, Pid_Sof_NoChan
    bau         r11                                   // Branch on PID to relevant token handing code 
                                                      // (e.g. in utmi_out.S etc). When done branchs back to NextToken
#endif
#else

    // ARCH_G code
        
    ldaw        r8, dp[crc5Table_Addr]
    ldaw        r1, dp[PidJumpTable]
    ldw         r6, dp[crcmask]
    ldc         r10, 16
        
ReadToken:
    inpw        r11, res[RXD], 8                       // Read 3 byte token from data port | CRC[5] | EP[4] | ADDR[7] | PID[8] | junk
    setpsc      res[RXD], r10
    shr         r11, r11, 24        

JumpOnPid:
    ldw         r1, r1[r11]
    .xtabranch  Pid_Out, Pid_Sof, Pid_In, Pid_Setup
    bau         r1

BadCrcAddr:
//    zext        r11, 8
//    ldc        r10, PIDn_SOF
//    eq         r11, r11, r10
//    bt         r11, Pid_Sof                              // TODO we should really CRC SOFs

    ldw        r1, sp[10]           		             
waitforRXALow0:  
    in        r10, res[r1]
    bt        r10, waitforRXALow0
    setc      res[RXD], XS1_SETC_RUN_CLRBUF   
        

    bu      Loop_BadPid

#endif


// Un-implemented PID list
Pid_Reserved:                                  // Should never get here     
//Pid_Out:          
Pid_Ack: 
//Pid_Ping:           
//Pid_Sof:                                           // Should never get here: (G4) hardware swallows SOF       
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
Pid_Bad:                                           // Bad PID received, ignore
    
InvalidToken:  
    ldw        r10, sp[10]           		        // Load RxA Port ID (r1) 
waitforRXALow:  

    in         r11, res[r10]
    bt         r11, waitforRXALow
    setc       res[RXD], XS1_SETC_RUN_CLRBUF   

   
    bu         Loop_BadPid                                 // Invalid token received Ignore unknown toks


.align 4
Return:
    ldw        r11, sp[8]                       # Free timers
    freer      res[r11]
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
