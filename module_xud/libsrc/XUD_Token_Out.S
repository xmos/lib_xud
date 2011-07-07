// r10: EP number
// OUT Token Packet -----------------------------------------------------------------------------
// Ports
#define RXD r0
#define TXD r2
#define RXE r3

.align 4
.skip 0
.cc_top Pid_Out.func, Pid_Out
Pid_Out:
#ifdef ARCH_L        
    inpw      r10, res[RXD], 8;                        /* Read EP Number */ 
    shr       r10, r10, 24;                            /* Shift off junk */  

    in         r11, res[r1];  
    bf         r11, InvalidToken;                       /* If VALID_TOKEN not high, ignore token */
#else
    // ARCH_G
    #include "XUD_G_Crc.S"               
#endif
        
    ldw       r5, r5[r10]                       // Load relevant EP chanend
    bf        r5, PrimaryBufferFull

//.align 4
OutReady:
    in          r11, res[r5]
    ldw       r4, sp[(STACK_EXTEND+5)]          // Load ep type table
    ldw       r4, r4[r10]                       // load EP type

    ldw       r10, sp[10]           		        // Load RxA Port ID (r1)
ReadDataPidByte:
    bl        doRXData
        
CheckEpTypeOut:    
    //ldw       r4, r4[r10]                     // load EP type
    bf        r4, CalcDataLength              // ISO endpoint 
        
    bf        r7, ReportBadCrc                // Check for bad crc


DoOutHandShakeOut:                            // Data CRC good and EP not Iso: Send Ack
    ldc       r11, PIDn_ACK
    outpw     res[TXD], r11, 8
    syncr   res[TXD]        

CalcDataLength:                               // Calculate length of received data (in bytes)
    //shl       r4, r4, 2                       // Convert complete received words to bytes 

    //add       r4, r4, r8                      // r4: total bytes
StoreTailDataOut:
    //stw       r3, r5[r4]
    out       res[r5], r6
        
    shr       r8, r8, 3                       // r8: number of tail bits, convert to bytes
        
    add       r8, r8, 10                      // TODO could just send num bits instead of bytes + 10
    outct     res[r5], r8                     // Send tail length
   // outct     res[r5], XS1_CT_END             // Close route
    //chkct     res[r5], XS1_CT_END

 
 

PidSequenceCheck:                         // Check PID sequencing, if bad we still send ACK, but junk data.
  //ldaw      r11, dp[ep_pid_sequence_table_OUT]
  //shr       r6, r6, 24                    // Shift off junk off data PID byte
  //ld8u      r9, r11[r10]
  //eq        r6, r6, r9
  //bf        r6, Err_BadPidSeq 
 
//ToggleDataPid:                            // Toggle data pid and save back 
  //ldc       r6, 0x8
  //xor       r9, r9, r6
  //st8       r9, r11[r10] 

// Data is ok, data saved in primary buffer (as there was room)
// Trigger bufferManager with datalength received
TriggerBufferManager:
    //ldw       r11, sp[18]                   // Load channel from stack (5th arg)
    //out       res[r11], r4                  // Send data length to bufferManager
    //out       res[r11], r10                 // ...and EP number

BadDataCrcOut:
    bu        NextTokenAfterOut

ReportBadCrc:
//  ecallf    r7
//    in        r0, res[RXD]
//    ecallf    r7
        
    outct     res[r5], 9                    // Send 9 for bad CRC 
    bu        NextToken

// Various Error handling functions -------------------------------------------------------------------
Err_RxErr:                                // RxError signal high during data packet receive:
  ldw       r10, sp[10]
  in        r11, res[r10]            // Wait for rxa low and ignore packet (let transaction timout)
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
        
  ldw       r4, sp[(STACK_EXTEND+5)]          // Load ep type table      
  ldw       r4, r4[r10]                       // load EP type
  bf        r4, PrimaryBufferFull_NoNak

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
