// r10: EP number
// OUT Token Packet -----------------------------------------------------------------------------
// Ports
#define RXD r0
#define TXD r2

.align 4
.skip 0
.cc_top Pid_Out.func, Pid_Out
Pid_Out:
#ifdef ARCH_L        
    inpw       r10, res[RXD], 8;                // Read EP Number */ 
    shr        r10, r10, 24;                    // Shift off junk */  

    in         r4, res[r1];  
    bt         r4, InvalidToken;               // If VALID_TOKEN not high, ignore token */
#else
    // ARCH_G
    #include "XUD_G_Crc.S"               
#endif
        
    ldw        r3, r5[r10]                      // Load relevant EP pointer
    bf         r3, PrimaryBufferFull
    ldw        r1, r3[3]                        // Load buffer

OutReady:
    
    bl         doRXData
        
CheckEpTypeOut:    
    //ldw        r4, r3[5]                        // Load EP type
    //bf         r4, StoreTailDataOut             // ISO endpoint 

      
    //ecallf         r7  
    bf         r1, ReportBadCrc                 // Check for bad crc


DoOutHandShakeOut:                              // Data CRC good and EP not Iso: Send Ack
    ldc        r11, PIDn_ACK
    outpw      res[TXD], r11, 8
    syncr      res[TXD]        

StoreTailDataOut:
    shr        r8, r8, 3                        // r8be : number of tail bits, convert to bytes
 
    ldc        r7, 0
    //stw        r3, r5[r10]                    // Load relevant EP pointer
    
    ldw        r11, r5[r10]                     // Load relevant EP pointer
    stw        r7, r5[r10]                    // Clear
    ldw        r5, r11[1]                       // Load chanend
                                                // TODO... CLEAR READY!!
        
    out        res[r5], r4                     // Output datalength (words)
    outt       res[r5], r8                      // Send tail length

BadDataCrcOut:
    bu        NextTokenAfterOut

ReportBadCrc: 
    //ecallf     r1
    //mov         r0, r11 
    //mov         r1, r11   
    //bl        ERR_BadCrc     
    //bu ReportBadCrc                         // Don't notify EP thread
    bu        NextToken

// Various Error handling functions -------------------------------------------------------------------
Err_RxErr:                                      // RxError signal high during data packet receive:
    ldw       r10, sp[10]
    in        r11, res[r10]                     // Wait for rxa low and ignore packet (let transaction timout)
    bu        NextToken
   
Err_EndpointProblem:                   
  // TODO:Endpoint in trouble (send STALL) or disabled (ignore?)...
  bu        NextToken

//Err_BadDataCrc:                         // Data packet received with bad crc: Ignore; wait for timeout (host will re-send)
  //bu        NextToken
  
Err_BadPidSeq:                            // Bad pid sequencing (already ACKed good data).  Ignore data
  bu        NextToken

PrimaryBufferFull:                        // Wait for end of data then send NAK
  ldw       r9, dp[flag1_port]
  setc      res[r9], XS1_SETC_RUN_CLRBUF  
  setc      res[r9], XS1_SETC_COND_NEQ 
  in        r11, res[r9]
  setc      res[r9], XS1_SETC_COND_EQ 
  in        r11, res[r9]
                                              // TODO: Observe interpacket delay 
  nop
  nop
  nop
        
  //ldw       r4, sp[(STACK_EXTEND+5)]          // Load ep type table      
  //ldw       r4, r4[r10]                       // load EP type
  //bf        r4, PrimaryBufferFull_NoNak

  // LOAD HANDSHAKE PID or STALL
  ldaw       r5, dp[handshakeTable_OUT]                // Load handshake table
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
  bl	ERR_OutDataTimeout
  bu Loop


    
.cc_bottom Pid_Out.func
