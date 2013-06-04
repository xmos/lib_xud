
.text 

WaitForEndDataPacket:
    ldw        r10, sp[10]           		    // Load RxA Port ID (r1) 
    in         r11, res[r10]
    bt         r11, waitforRXALow
    setc       res[RXD], XS1_SETC_RUN_CLRBUF 
    bu         NextTokenAfterOut

// Expects 
// r5: buffer address 
// RXD: Rx Data port
// r4: zero
// r7: crc init
// r9: crc poly
.cc_top doRXData.func, doRXData
.align 4
.skip 2
doRXData:
    ldw         r11, sp[10]           	        // Load RxA Port ID (r1) 
    in          r8, res[r11]                    // By doing an in we clear any previous event data - saves us havin to reload the port ID later...
    inpw        r8, res[r0], 8                  // Input PID
GotRxPid:
    stw         r8, r3[6]                       // Store (NON-SHIFTED) PID into EP structure
    eeu         res[r11] 
    setsr       1                               // Enable thread events

.align 4
.skip 0
NextRxWord:				                        // RXD port has event vector here
    in 	        r8, res[r0]
    crc32       r6, r8, r9
    stw         r8, r1[r4]
    add         r4, r4, 1
.xtabranch NextRxWord, RxALow
    bu          NextRxWord

/////////////////////////////////////////////////////////////////////////////
.align 16
.skip 10
RxALow:
    endin       r8, res[r0]
XUD_OUT_RxTail:
    in          r7, res[r0]

.xtabranch OutTail0, OutTail1, OutTail2, OutTail3, OutTail4, OutTail5
    bru	        r8

// Word aligned data (0 byte tail)
.align 16
OutTail0:
    crc32       r6, r8, r9                      // CRC zero step                    
    ldc         r11, 0x7000                     // Load relevant CRC magic number
    retsp       0

// 1 Tail Byte
.align 16
OutTail1:
    ldc         r11, 0x80be                     // Load CRC magic number             
    shr         r7, r7, 24                      // Shift off junk
    crc32       r6, r7, r9
    retsp       0

// Two Tail Bytes
.align 16
OutTail2:
    ldc         r11, 0x3ffe
    shr         r7, r7, 16
    crc32       r6, r7, r9
    retsp       0

// Three Tail Bytes
.align 16
OutTail3:
    shr         r7, r7, 8
    crc32       r6, r7, r9
    crc8        r6, r9, r2, r9 // Massive hack - use the fact the the bottom byte of port id is 0.. saves us a ldc 
    ldw         r11, sp[12]
    retsp       0

// Four Tail Bytes
.align 16
OutTail4:
    ldc         r11, 0
    //retsp 0
    ecallf      r11

// Five Tail Bytes
.align 16
OutTail5:
    mov         r0, r6
    bu          ERR_EndIn5

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

    in         r4, res[r1]; 
    bt         r4, InvalidToken;                       /* If VALID_TOKEN not high, ignore token - PORT INVERTED*/
#else
    #include "XUD_G_Crc.S"       
#endif
    ldw        r3, r5[r10]                      // Load relevant EP pointer
    bf         r3, SBuffFull
    ldw        r1, r3[3]                        // Load buffer
       
        
SetupReady:	
    //ldw       r10, sp[10]                       // Load RxA Port ID (r1)        
                                                // TODO Do a timeout here?

LoadSetupBuffer:
    bl          doRXData			            // RXData writes available data to buffer and does crc check. 
                                                // r7: CRC check	
                                                // r8: Data tail size (bytes)  
    clre
    stw         r7, r1[r4]                      // Store last data
    eq          r1, r6, r11                     // Check for good CRC16
       
doRXDataReturn_:
    ldw         r11, dp[flag1_port]
    in          r11, res[r11]

DoOutHandShake:                                 // Data CRC good: Send Ack
                                                // Have received a SETUP so clear any STALL condition on IN/OUT endpoint. 
    ldaw        r11, dp[handshakeTable_OUT]
    ldc         r7, PIDn_NAK
    stw         r7, r11[r10]
    ldaw        r11, dp[handshakeTable_IN]
    stw         r7, r11[r10]

    
StoreTailData:                                  // TODO: don't assume setups are 8 bytes + crc
    ldw         r3, r5[r10]                      // Load relevant EP pointer
    ldc         r11, 0
    stw         r11, r5[r10]        
    ldw         r5, r3[1]                       // Load chanend

    ldc         r11, PIDn_ACK
    outpw       res[TXD], r11, 8

    out         res[r5], r10    
    outct       res[r5], 0                      // Send zero control token for SETUP. Tail ignored since always expect 8 bytes            
    bu          NextToken 				        // Go to next wait for next token 


SBuffFull:
    ldc         r11, 0
//    ecallf      r11
 //   bl          ERR_SetupBuffFull			    // Wait for end of data then go to next token
    ldw         r10, sp[10]                     // Load RxA Port ID (r1)
    in 	        r11, res[r10]			        // RXA event cond = 0 TODO: Wait for RXA high first?
    endin       r11, res[RXD]
    in          r11, res[RXD]

    bu          NextTokenAfterOut

BadDataCrcSetup:
    mov r0, r1
    bl          ERR_BadCrc
    outct       res[r5], 9
    in          r11, res[r5]                    // TODO should only need CT  
    bu          NextToken
.cc_bottom Pid_Setup.func
