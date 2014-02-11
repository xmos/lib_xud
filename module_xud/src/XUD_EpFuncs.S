/** XUD_EpFuncs.S
  * @brief     Functions for data transfer to/from XUD
  * @author    Ross Owen, XMOS Limited
  */
#include "usb_defs.h"
#include "xud_defines.h"

//int XUD_GetSetupData(XUD_ep e_out, XUD_ep in, unsigned buffer[]);
//                     r0            r1         r2
.globl XUD_GetSetupData
.type XUD_GetSetupData, @function
.text

.cc_top XUD_GetSetupData.func
.align 2
ResetSuspendSetup:
    mkmsk      r0, 32                           // Return -1 as length
    ldw         r10, sp[2]
    ldw         r4, sp[1]
    retsp      4

XUD_GetSetupData:

    entsp       4
    stw         r4, sp[1]
    stw         r10, sp[2]

XUD_GetSetupData_:
    ldw        r4, r0[0]                        // Load mem address of EP structure
    stw        r2, r0[3]
    stw        r0, r4[0]
    ldw        r10, r0[2]


XUD_GetSetupData_Retry:
    testct     r11, res[r10]                      // Test whether there is a RESET/SUSPEND exception
    bt         r11, ResetSuspendSetup

XUD_GetSetupData_NoReq:                         // Entry for _NoReq
    in         r3, res[r10]                     // Input packet "word" length
    testct     r11, res[r10]                    // CT means we got a SETUP (not OUT).
    bf         r11, XUD_GetSetupData_GotOut
    inct        r11, res[r10]                   // Always get 0 (expect 8 bytes data)

//XUD_GetSetupData_CheckPid:
                                                // We expect data0 else something gone wrong...
                                                // TODO..

XUD_GetSetupData_ResetPid:                      // We must reset PID toggling on SETUP (both IN AND OUT)
#if (XUD_SERIES_SUPPORT==3)
    ldc         r11, USB_PIDn_DATA1
#else
    ldc         r11, USB_PID_DATA1
#endif
    stw         r11, r0[4]                      // Reset OUT toggle

    ldc         r11, USB_PIDn_DATA1
    stw         r11, r1[4]                      // Reset IN toggle

    ldc         r0, 8                           // Return 8 byte length (TODO really could return actual length here)
    ldw         r10, sp[2]
    ldw         r4, sp[1]
    retsp       4

XUD_GetSetupData_GotOut:                        // Got an OUT intead not a SETUP
    int         r11, res[r10]

    shl         r3, r3, 2                       // Num received words to bytes
    add         r3, r11, r3                     // r11: Total bytes received (Note this includes 2 byte crc)

XUD_GetSetupData_CheckPid:
    ldw         r11, r0[6]                      // Load received PID from EP structure
    shr         r11, r11, 24                    // Shift down due to inpw
    ldw         r10, r0[4]                      // Load expected PID

    xor         r11, r10, r11                   // Do the comparison
    bt          r11, XUD_GetSetupData_          // Ignore packet...

XUD_GetSetupData_PidOkay:
    stw         r11, r4[0]                      // Zero ready entry (NOTE R11 0 from branch above)
                                                // TODO is there a race here? Should this happen in XUD thread?

    ldw         r11, r0[5]                      // Load EP type
    bf          r11, XUD_GetSetupData_ReturnOk  // Jump over PID toggle for ISO

XUD_GetSetupData_PidToggle:
    ldc         r11, 8
    xor         r10, r10, r11
    stw         r10, r0[4]

XUD_GetSetupData_ReturnOk:
    sub         r0, r3, 2                       // Length correction for CRC correction (return val in r0)

    ldw         r10, sp[2]
    ldw         r4, sp[1]
    retsp       4

.size XUD_GetSetupData, .-XUD_GetSetupData
.cc_bottom XUD_GetSetupData.func
.globl XUD_GetSetupData.nstackwords
.globl XUD_GetSetupData.maxchanends
.globl XUD_GetSetupData.maxtimers
.globl XUD_GetSetupData.maxcores
.set XUD_GetSetupData.nstackwords, 4
.set XUD_GetSetupData.maxchanends, 0
.set XUD_GetSetupData.maxtimers, 0
.set XUD_GetSetupData.maxcores, 1


.cc_top XUD_SetData_Select.func


//void XUD_SetData_Select(chan c, XUD_ep ep, unsigned &x);
//                        r0,     r1         r2
.globl XUD_SetData_Select
.type XUD_SetData_Select, @function
.align 2
XUD_SetData_Select:
    entsp       4
    stw         r4, sp[1]

    testct      r3, res[r0]
    bt          r3, XUD_SetData_Select_Return_ResetSuspend

    in          r3, res[r0]                     // Data sent okay

XUD_SetData_LoadEpType_:
    ldw         r11, r1[5]                      // Don't do any toggling for ISO
    bf          r11, XUD_SetData_DonePid_

XUD_SetData_PidToggle_:
    ldw         r11, r1[4]                      // Load EP PID from structure
    ldc         r4, 0x88
    xor         r11, r11, r4
    stw         r11, r1[4]                      // Store back PID

XUD_SetData_DonePid_:
    ldw         r4, sp[1]
    retsp       4

XUD_SetData_Select_Return_ResetSuspend:
    mkmsk       r0, 32                           // Return -1 as length
    stw         r0, r2[0]
    ldw         r4, sp[1]
    retsp       4
.size XUD_SetData_Select, .-XUD_SetData_Select
.cc_bottom XUD_SetData_Select.func
.globl XUD_SetData_Select.nstackwords
.globl XUD_SetData_Select.maxchanends
.globl XUD_SetData_Select.maxtimers
.globl XUD_SetData_Select.maxcores
.set XUD_SetData_Select.nstackwords, 4
.set XUD_SetData_Select.maxchanends, 0
.set XUD_SetData_Select.maxtimers, 0
.set XUD_SetData_Select.maxcores, 1


//void XUD_GetData_Select(chan c, XUD_ep ep, unsigned &x);
//                        r0,     r1         r2
.globl XUD_GetData_Select
.type XUD_GetData_Select, @function

.cc_top XUD_GetData_Select.func
XUD_GetData_Select:                             // Entry for _NoReq
    testct     r3, res[r0]
    bt         r3, XUD_GetData_Select_Return_ResetSuspend
    in         r3, res[r0]                      // Input packet "word" length
    int        r11, res[r0]                     // r11 is tail length (bytes)
	shr		   r11, r11, 3

XUD_GetData_Select_CalcdataLength:
    shl        r3, r3, 2                        // Num received words to bytes
    add        r3, r11, r3                      // r11: Total bytes received (Note this includes 2 byte crc)


    ldw         r11, r1[5]                      // Load EP type
    bf          r11, XUD_GetData_Select_Return  // Jump over PID toggle and check for ISO


XUD_GetData_Select_CheckPid:                    // Check PID
    ldw         r11, r1[6]                      // Load received PID from EP structure
    shr         r11, r11, 24                    // Shift off junk

                                                // Note: We can't just jump back to XUD_GetData_Select since other EP's might need service

    ldw         r0, r1[4]                       // Load expected PID
    xor         r11, r0, r11                    // Do the comparison
    bt          r11, XUD_GetData_Select_BadPkt  // TODO Currently report 0 length packet received, not ideal.

XUD_GetData_Select_PidToggle:
#if (XUD_SERIES_SUPPORT==3)
    ldc         r11, 0x88
#else
    ldc         r11, 8
#endif
    xor         r0, r0, r11
    stw         r0, r1[4]

XUD_GetData_Select_Return:
    sub         r0, r3, 2                       // Length correction for CRC correction (return val in r0)

    ashr        r11, r0, 32                     // Check for < 0. No CRC check on ISO so less than 2 bytes could be received.
    bt          r11, XUD_GetData_Select_BadPkt

    stw         r0, r2[0]                       // Return length (note: passed by ref)
    retsp       0

XUD_GetData_Select_BadPkt:
    ldc         r0, 0                           // Return 0 length
    stw         r0, r2[0]                       // Return length (note: passed by ref)
    retsp       0

XUD_GetData_Select_Return_ResetSuspend:
    mkmsk       r0, 32                          // Return -1 as length
    stw         r0, r2[0]
    retsp       0

.size XUD_GetData_Select, .-XUD_GetData_Select
.cc_bottom XUD_GetData_Select.func
.globl XUD_GetData_Select.nstackwords
.globl XUD_GetData_Select.maxchanends
.globl XUD_GetData_Select.maxtimers
.globl XUD_GetData_Select.maxcores
.set XUD_GetData_Select.nstackwords, 0
.set XUD_GetData_Select.maxchanends, 0
.set XUD_GetData_Select.maxtimers, 0
.set XUD_GetData_Select.maxcores, 1

//int XUD_GetData(XUD_ep c, unsigned char buffer[]);
.globl XUD_GetData
.type XUD_GetData, @function
.text

.cc_top XUD_GetData.func
.align 2
XUD_GetData:
    entsp       16
    stw         r10, sp[1]
    mov         r11, r1

XUD_GetData_:
    ldw        r2, r0[0]                        // Load mem address of EP structure
    stw        r1, r0[3]
    stw        r0, r2[0]

XUD_GetData_Retry:
    ldw        r10, r0[2]                       // Load our chanend ID to use
                                                // Wait for XUD response
    testct     r11, res[r10]                    // Test whether there is a RESET/SUSPEND exception
    bt         r11, ResetSuspend

XUD_GetData_DataEnd:
    in         r3, res[r10]                     // Input packet "word" length
    int        r11, res[r10]                    // r11 is tail length (bytes)
    shr        r11, r11, 3

XUD_GetDataCalcDataLength:
    shl        r3, r3, 2                        // Num received words to bytes
    add        r3, r11, r3                      // r11: Total bytes received (Note this includes 2 byte crc)

XUD_GetData_CheckPid:
    ldw        r11, r0[6]                       // Load received PID from EP structure
    shr        r11, r11, 24                     // Shift down due to inpw
    ldw        r10, r0[4]                       // Load expected PID

    xor        r11, r10, r11                    // Do the comparison
    bt         r11, XUD_GetData_                // Ignore packet...

XUD_GetData_PidOkay:
    //stw        r11, r2[0]                     // Zero ready entry (Note, R11 0 from branch above)
                                                // Now done in the XUD core

    ldw        r11, r0[5]                       // Load EP type
    bf         r11, XUD_GetData_ReturnOk        // Jump over PID toggle for ISO

XUD_GetData_PidToggle:
#if (XUD_SERIES_SUPPORT==3)
    ldc        r11, 0x88
#else
    ldc        r11, 8
#endif
    xor        r10, r10, r11
    stw        r10, r0[4]

XUD_GetData_ReturnOk:
    sub        r0, r3, 2                        // Length correction for CRC correction (return val in r0)
    ldw        r10, sp[1]                       // TODO should check for <0 as ISO doesn't have CRC check
    retsp      16

ResetSuspend:
    mkmsk      r0, 32                           // Return -1 as length

Return:
    ldw        r10, sp[1]
    retsp      16

.size XUD_GetData, .-XUD_GetData
.cc_bottom XUD_GetData.func
.globl XUD_GetData.nstackwords
.globl XUD_GetData.maxchanends
.globl XUD_GetData.maxtimers
.globl XUD_GetData.maxcores
.set XUD_GetData.nstackwords, 16
.set XUD_GetData.maxchanends, 0
.set XUD_GetData.maxtimers, 0
.set XUD_GetData.maxcores, 1

// Note: Assumes startIndex is word aligned
//int XUD_SetData_indexed(chanend c, unsigned buffer[], unsigned datasize, unsigned startIndex unsigned pid);
//                        r0         r1                 r2                 r3

.globl XUD_SetData
.type XUD_SetData, @function
.text

.cc_top XUD_SetData.func
.align 2
XUD_SetData:
    entsp       7
    stw         r5, sp[5]
    stw         r10, sp[6]

XUD_SetDataRetry:
    stw         r4, sp[0]

XUD_SetData_NoReq:
    add         r1, r1, r3                      // Add start index to buffer address

CalcTailLength:
    shl         r3, r2, 5                       // Taillength: bytes to bits * 2
    zext        r3, 7

SetupLoopTerm:
    shr         r2, r2, 2                       // r2: datalength (bytes) ---> r2: datalength (words)

AdjustBufferPointer:
    shl         r5, r2, 2                       // Get end off buffer address
    add         r1, r1, r5

NegativeIndex:                                  // Produce negtive offset from end of buffer
    neg         r2, r2
    stw         r2, r0[6]                       // Store index

XUD_SetData_DataRdy:
    ldw         r2, r0[0]                       // Load mem address of EP structure
    stw         r1, r0[3]                       // Store buffer address
StoreTailLength:
    stw         r3, r0[7]                       // Store tail length (bytes)

    stw         r0, r2[0]                       // Mark ready with address of ep structure

                                                // Wait for XUD Response
    ldw         r10, r0[2]                      // Load our chanend ID to use
    testct      r11, res[r10]                   // Test for RESET/SUSPEND exception
    bt          r11, XUD_SetData_Reset

    in          r11, res[r10]                   // Data sent okay

XUD_SetData_LoadEpType:
    ldw         r11, r0[5]                      // Don't do any toggling for ISO
    bf          r11, XUD_SetData_DonePid

XUD_SetData_PidToggle:                          //
    ldw         r11, r0[4]                      // Load EP PID from structure
    ldc         r4, 0x88
    xor         r11, r11, r4
    stw         r11, r0[4]                      // Store back PID

XUD_SetData_DonePid:
    ldc         r0, 0
XUD_SetData_Return:
    ldw         r4, sp[0]
    ldw         r5, sp[5]
    ldw         r10, sp[6]
    retsp       7

XUD_SetData_Reset:
    mkmsk       r0, 32                           // Return -1
    bu          XUD_SetData_Return

.size XUD_SetData, .-XUD_SetData
.cc_bottom XUD_SetData.func
.globl XUD_SetData.nstackwords
.globl XUD_SetData.maxchanends
.globl XUD_SetData.maxtimers
.globl XUD_SetData.maxcores
.set XUD_SetData.nstackwords, 7
.set XUD_SetData.maxchanends, 0
.set XUD_SetData.maxtimers, 0
.set XUD_SetData.maxcores, 1


.globl XUD_ResetEndpoint
.type XUD_ResetEndpoint, @function

.cc_top XUD_ResetEndpoint.func
.align 2
XUD_ResetEndpoint:
    entsp       1
    ldw         r0, r0[2]
    bf          r1, .L0
    ldw         r1, r1[0]
    ldw         r1, r1[2]
.L0:
    bl XUD_ResetEndpoint0
    retsp       1
.size XUD_ResetEndpoint, .-XUD_ResetEndpoint
.cc_bottom XUD_ResetEndpoint.func
.globl XUD_ResetEndpoint.nstackwords
.globl XUD_ResetEndpoint.maxchanends
.globl XUD_ResetEndpoint.maxtimers
.globl XUD_ResetEndpoint.maxcores
.set XUD_ResetEndpoint.nstackwords, 1 + XUD_ResetEndpoint0.nstackwords
.set XUD_ResetEndpoint.maxchanends, XUD_ResetEndpoint0.nstackwords
.set XUD_ResetEndpoint.maxtimers, XUD_ResetEndpoint0.nstackwords
.set XUD_ResetEndpoint.maxcores, XUD_ResetEndpoint0.nstackwords

.globl XUD_SetStallByAddr
.type XUD_SetStallByAddr, @function

/* R0: ep number */
.cc_top XUD_SetStallByAddr.func
.align 2
XUD_SetStallByAddr:
    ldc         r2, USB_PIDn_STALL
    ldc         r11, 0x80                       // Check for IN bit
    and         r11, r11, r0
    bf          r11, XUD_SetStallByAddr_OUT
    ldaw        r1,  dp[handshakeTable_IN]
    mkmsk       r11, 7
    and         r11, r11, r0
    stw         r2, r1[r11]
    retsp       0
XUD_SetStallByAddr_OUT:
    ldaw        r1,  dp[handshakeTable_OUT]
    stw         r2, r1[r0]
    retsp       0
.size XUD_SetStallByAddr, .-XUD_SetStallByAddr
.cc_bottom XUD_SetStallByAddr.func
.globl XUD_SetStallByAddr.nstackwords
.globl XUD_SetStallByAddr.maxchanends
.globl XUD_SetStallByAddr.maxtimers
.globl XUD_SetStallByAddr.maxcores
.set XUD_SetStallByAddr.nstackwords, 0
.set XUD_SetStallByAddr.maxchanends, 0
.set XUD_SetStallByAddr.maxtimers, 0
.set XUD_SetStallByAddr.maxcores, 1


.globl XUD_ClearStallByAddr
.type XUD_ClearStallByAddr, @function

/* R0: ep number */
.cc_top XUD_ClearStallByAddr.func
.align 2
XUD_ClearStallByAddr:
    ldc         r2, USB_PIDn_NAK
    ldc         r11, 0x80                       // Check for IN bit
    and         r11, r11, r0
    bf          r11, XUD_ClearStallByAddr_OUT
    ldaw        r1,  dp[handshakeTable_IN]
    mkmsk       r11, 7
    and         r11, r11, r0
    stw         r2, r1[r11]
    retsp       0
XUD_ClearStallByAddr_OUT:
    ldaw        r1,  dp[handshakeTable_OUT]
    stw         r2, r1[r0]
    retsp       0
.size XUD_ClearStallByAddr, .-XUD_ClearStallByAddr
.cc_bottom XUD_ClearStallByAddr.func
.globl XUD_ClearStallByAddr.nstackwords
.globl XUD_ClearStallByAddr.maxchanends
.globl XUD_ClearStallByAddr.maxtimers
.globl XUD_ClearStallByAddr.maxcores
.set XUD_ClearStallByAddr.nstackwords, 0
.set XUD_ClearStallByAddr.maxchanends, 0
.set XUD_ClearStallByAddr.maxtimers, 0
.set XUD_ClearStallByAddr.maxcores, 1

.globl XUD_ResetEpStateByAddr
.type XUD_ResetEpStateByAddr, @function

/* R0: ep number */
.cc_top XUD_ResetEpStateByAddr.func
.align 2
XUD_ResetEpStateByAddr:
    ldc         r11, 0x80
    and         r2, r0, r1
    bf          r2, XUD_ResetEpStateByAddr_OUT
    ldc         r1, USB_PIDn_DATA0
    bu          XUD_ResetEpStateByAddr_
XUD_ResetEpStateByAddr_OUT:
#if(XUD_SERIES_SUPPORT==3)
    ldc         r1, USB_PIDn_DATA0
#else
    ldc         r1, USB_PID_DATA0
#endif
XUD_ResetEpStateByAddr_:
    zext        r0, 7                           // Check for IN bit set
    bf          r2, NoOffset
    ldaw        r0, r0[4]                       // Assume MAX_NUM_EP_OUT is 16 here! (r0 = r0 + 4 * 4)
NoOffset:
    ldc         r2, 36                          // Size of XUD_ep_info struct
    mul         r0, r0, r2
    ldaw        r2, dp[ep_info]
    add         r0, r2, r0
    stw         r1, r0[4]
    retsp       0
.size XUD_ResetEpStateByAddr, .-XUD_ResetEpStateByAddr
.cc_bottom XUD_ResetEpStateByAddr.func
.globl XUD_ResetEpStateByAddr.nstackwords
.globl XUD_ResetEpStateByAddr.maxchanends
.globl XUD_ResetEpStateByAddr.maxtimers
.globl XUD_ResetEpStateByAddr.maxcores
.set XUD_ResetEpStateByAddr.nstackwords, 0
.set XUD_ResetEpStateByAddr.maxchanends, 0
.set XUD_ResetEpStateByAddr.maxtimers, 0
.set XUD_ResetEpStateByAddr.maxcores, 1

