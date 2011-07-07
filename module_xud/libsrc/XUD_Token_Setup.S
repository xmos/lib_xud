
.text 

// Expects 
// r5: buffer address 
// RXD: Rx Data port
// r4: zero
// r7: crc init
// r9: crc poly
.cc_top doRXData.func, doRXData
.align 4
.skip 0
doRXData:
    ldc         r7, 0x3334                             // CRC16 init (out)
    out         res[r5], r5

        
    inpw        r8, res[RXD], 8 
    stw         r8, dp[data_pid]
    eeu         res[RXD]        
    eeu         res[r10]                         // Enable events on RXA

                
    .xtabranch NextRxWord, RxALow
    waiteu				                            // Wait for data or RXA low

.align 4 
NextRxWord:				                            // RXD port has event vector here
    in 	        r8, res[RXD]
    out         res[r5], r8
    crc32       r7, r8, r9
    .xtabranch NextRxWord, RxALow
    waiteu 


/////////////////////////////////////////////////////////////////////////////
.align 16
.skip 10
RxALow:
    endin   r8, res[RXD]
XUD_OUT_RxTail:
    in      r6, res[RXD]
    .xtabranch OutTail0, OutTail1, OutTail2, OutTail3, OutTail4, OutTail5
    bru	    r8

// Word aligned data (0 byte tail)
.align 16
OutTail0:
    ldc     r11, 0x7000                  // Load relevant CRC magic number
    crc32   r7, r8, r9                   // CRC zero step                    
    bu      CheckCrc16

// 1 Tail Byte
.align 16
OutTail1:
    ldc     r11, 0x80be                   // Load CRC magic number             
    shr     r6, r6, 24                    // Shift off junk
    crc32   r7, r6, r9
    bu      CheckCrc16

// Two Tail Bytes
.align 16
OutTail2:
    ldc     r11, 0x3ffe
//    bf      r4, CheckCrc16               // Skip CRC for iso packets
    //bf      r1, StoreTailData
    shr     r6, r6, 16
    crc32   r7, r6, r9
    BRFU_u6 CheckCrc16

// Three Tail Bytes
.align 16
OutTail3:
    ldc    r11, 0        
    shr    r6, r6, 8
    crc32  r7, r6, r9
    crc32  r7, r11, r9 
    //ldc    r11, 0x0070
    ldw      r11, sp[12]
    BRFU_u6     CheckCrc16

// Four Tail Bytes
.align 16
OutTail4:
    bu     ERR_EndIn4


.align 16
OutTail5:
    mov    r0, r6
    bu     ERR_EndIn5


SendNak:
    ldc     r11, PIDn_NAK
    outpw   res[TXD], r11, 8
    bu      doRXDataReturn



.align 4
.skip 0
CheckCrc16:    
    eq      r7, r7, r11                              // Check for good CRC16
       
doRXDataReturn:
    in     r10, res[r10]
    retsp   0
    
    .cc_bottom doRXData.func
    

.text 


.cc_top Pid_Setup.func, Pid_Setup
.align 4

    

// We received a setup token.  This is much the same as out token, apart from:
// - Can't NAK a setup
// - Data PID will always be DATA0
// - Payload will always be 8 bytes
// r10 = ep number

Pid_Setup:
#ifdef ARCH_L        
    inpw      r10, res[RXD], 8;                        /* Read EP Number */ 
    shr       r10, r10, 24;                            /* Shift off junk */  

    in         r11, res[r1];  
    bf         r11, InvalidToken;                       /* If VALID_TOKEN not high, ignore token */
#else
    #include "XUD_G_Crc.S"       
#endif
        
    ldw       r5, r5[r10]
    bf        r5, SBuffFull
        
SetupReady:	
    ldw       r10, sp[10]                      // Load RxA Port ID (r1)        
                                              // TODO Do a timeout here?

LoadSetupBuffer:
    bl      doRXData			              // RXData writes available data to buffer and does crc check. 
                                              // r7: CRC check outcome	
                                              // r8: Data tail size (bytes)   
  bf      r7, BadDataCrcSetup

//CheckEpType:                                // Always handshake for control EP/Setup transactions
//  bf      r1, StoreTailData                       

DoOutHandShake:                               // Data CRC good: Send Ack
                                              
                                              // Have received a SETUP so clear any STALL condition on IN/OUT endpoint. 
    ldaw        r11, dp[handshakeTable_OUT]
    ldc         r7, PIDn_NAK
    stw         r7, r11[r10]
    ldaw        r11, dp[handshakeTable_IN]
    stw         r7, r11[r10]

    outct     res[r5], 1        
    in        r11, res[r5]                    // TODO should only need CT
        
    ldc     r11, PIDn_ACK
    outpw   res[TXD], r11, 8

StoreTailData:                                // TODO: don't assume setups are 8 bytes + crc
    //out       res[r5], r3
    //ldc       r3, 12
    //outct     res[r5], r3
   // outct     res[r5], XS1_CT_END
    //chkct     res[r5], XS1_CT_END

BadDataCrcSetupResume:                             
    bu NextToken 				// Go to next wait for next token 


SBuffFull:
 bl    ERR_SetupBuffFull			// Wait for end of data then go to next token
 ldw    r10, sp[10]                      // Load RxA Port ID (r1)
 in 	r11, res[r10]			// RXA event cond = 0 TODO: Wait for RXA high first?
 endin r11, res[RXD]
 in 	r11, res[RXD]

 bu NextTokenAfterOut

BadDataCrcSetup:
        outct     res[r5], 9
        in        r11, res[r5]                    // TODO should only need CT  
        bu BadDataCrcSetupResume
.cc_bottom Pid_Setup.func
