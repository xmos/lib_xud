#include <xs1.h>

// Ports
#define RXD r0
#define RXA r1
#define TXD r2
#define RXE r3

.text
// On entry:
// R11: Branch address (now free)
// R10: EP number  (used here)
// R9 : CRC16 Poly (used here)
// R8 : 
// R7 :  
// R6 : ep_pid_sequence_table_IN_A
// R5 : Channel Array
// R4 :  
// R3 : 0
// R2 : TXD
// R1 : Valid Token Port
// R0 : RXD  
.cc_top InNotReady.func, InNotReady
.align 4        
InNotReady:
    
    // LOAD HANDSHAKE (NAK OR STALL)   
    //ldc       r11, PIDn_NAK			                 // TODO Ensure min inter-packet delay  
    ldaw       r5, dp[handshakeTable_IN]                 // Load handshake table
    ldw        r11, r5[r10]                              // Load handshake PID
     
XUD_IN_TxNak:     
    outpw     res[TXD], r11, 8                           // Output handshake PID       
    bu        NextTokenAfterIn
.cc_bottom InNotReady.func


.cc_top Pid_In.func, Pid_In
.align 128
#ifdef ARCH_L        
.skip 94
#else
//.skip 90
.skip 84
#endif        
Pid_In:
#ifdef ARCH_L        
    inpw      r10, res[RXD], 8;                        /* Read EP Number */ 
    shr       r10, r10, 24;                            /* Shift off junk */  

    in         r11, res[r1];  
    bf         r11, InvalidToken;                       /* If VALID_TOKEN not high, ignore token */
#else
    #include "XUD_G_Crc.S"        
#endif

    //ldw         r11, sp[24]                         // Load EP channeltable 
    add         r11, r4, r10                       // IN channel offset (R10: EP number)        
    ldw         r5, r5[r11]                         // Load EP chan
        
    bf          r5, InNotReady
        
InReady:                                            
    out		    res[r5], r3                         // Reply to request to send (allows client to select)
    in          r11, res[r5]                        // Input PID

    inct        r8, res[r5]                         // Get Tail length
    testct      r6, res[r5]                         // Check for end of data stream

    bt          r6,  SmallTxPacket

.xtabranch TxTail0, TxTail1, TxTail2, TxTail3
    bru         r8                                  // Branch on tail length

//--------------------------------------------------------------------------
.align 64
.skip 0
TxTail0:
    in       r6, res[r5]                            // Get first data word
    testct   r8, res[r5]                            
XUD_IN_TxPid_Tail0:
    outpw    res[TXD], r11, 8                       // Out PID        
    out      res[TXD], r6
    crc32      r7, r6, r9
    //testct   r8, res[r5]                            
    bt         r8, TxLoop0End
TxLoop0:
    in       r6, res[r5]                            // Get data word
    testct   r11, res[r5]        
TxLoop0_Out:
    out      res[TXD], r6
    crc32      r7, r6, r9
    bf         r11, TxLoop0
TxLoop0End:                                         // Word aligned data (just output CRC)
    crc32        r7, r3, r9                         // R3: 0
    not          r7, r7

XUD_IN_TxCrc_Tail0:
    outpw        res[TXD], r7, 16
    inct         r6, res[r5]                        // Input end of stream token
    in           r6, res[r5]                        // Input tail data (junk)
    bu           DoneTail  

.align 64
.skip 0
TxTail1:
  in       r6, res[r5]                       // Get data word
  testct   r8, res[r5]
XUD_IN_TxPid_Tail1:
  outpw    res[TXD], r11, 8                   // Out PID        
  out      res[TXD], r6
  crc32      r7, r6, r9
  //testct   r8, res[r5]
  bt         r8, TxLoop1End
TxLoop1:
  in       r6, res[r5]                       // Get data word
  testct   r11, res[r5]        
  out      res[TXD], r6
  crc32      r7, r6, r9
  bf         r11, TxLoop1
TxLoop1End:  
  inct       r6, res[r5]                      // Input end of stream token
  in         r6, res[r5]                      // Input tail data              
  outpw        res[TXD], r6, 8 
  crc8         r7, r4, r6, r9
  crc32        r7, r3, r9                 // r3: 0 
  not          r7, r7

XUD_IN_TxCrc_Tail1:
  outpw        res[TXD], r7, 16
  bu           DoneTail

.align 64
.skip 0
TxTail2:
  in       r6, res[r5]                       // Get data word
  testct   r8, res[r5]
XUD_IN_TxPid_Tail2:
  outpw    res[TXD], r11, 8                   // Out PID        
  out      res[TXD], r6
  crc32      r7, r6, r9
  //testct   r8, res[r5]					  // BREAK TIMING IF TEST CT HERE (DATA TO CRC)
  bt         r8, TxLoop2End        
TxLoop2:
  in       r6, res[r5]                       // Get data word
  testct   r11, res[r5]        
  out      res[TXD], r6
  crc32      r7, r6, r9
  bf         r11, TxLoop2
TxLoop2End:
  inct       r6, res[r5]                      // Input end of stream token  
  in         r6, res[r5]                      // Input tail data              
  // Two tail byte q
        
  outpw        res[TXD], r6, 16 
  crc8         r7, r6, r6, r9
  crc8         r7, r6, r6, r9
  crc32        r7, r3, r9                 // r3: 0     
  not          r7, r7

XUD_IN_TxCrc_Tail2:
  outpw        res[TXD], r7, 16
  bu           DoneTail

.align 64
.skip 0
TxTail3:
  in       r6, res[r5]                       // Get data word
  testct   r8, res[r5]
XUD_IN_TxPid_Tail3:
  outpw    res[TXD], r11, 8                   // Out PID        
  out      res[TXD], r6
  crc32      r7, r6, r9
  //testct   r8, res[r5]			
  bt         r8, TxLoop3End
TxLoop3:
  in       r6, res[r5]                       // Get data word
  testct   r11, res[r5]        
  out      res[TXD], r6
  crc32      r7, r6, r9
  bf         r11, TxLoop3
TxLoop3End:
        
  inct       r6, res[r5]                      // Input end of stream token    
  in         r6, res[r5]                      // Input tail data        
  // Three tail byte  
  outpw        res[TXD], r6, 24 
  crc8         r7, r6, r6, r9
  crc8         r7, r6, r6, r9
  crc8         r7, r6, r6, r9
  crc32        r7, r3, r9                // r3: 0     
  not          r7, r7
XUD_IN_TxCrc_Tail3:
  outpw        res[TXD], r7, 16
  
// Wait for handshake... or timeout
DoneTail:
    syncr       res[TXD]
    //chkct         res[r5], XS1_CT_END
    ldw           r11, sp[22]       
    ldw           r11, r11[r10]                 // Load EP Type
    bt            r11, SetupReceiveHandShake

InISO:
    out           res[r5], r11                  // Output 0 to EP threaf for no error
    bu            NextToken

InNonISO:
SetupReceiveHandShake:			  
    ldc	       	 r11, 8
    setpsc       res[RXD], r11		            // Set port shift count (expect 8 bit handshake)
    ldap         r11,  TxHandShakeReceived
    setv         res[RXD], r11
    eeu		     res[RXD]                       // Events on RXD always enabled - Can;t be any more due to using events on channels

SetupTimeout:				                              // Timeout done using another port off same clock block we dont happen to already be using events on. Cunning.
    ldw 		r1, sp[11]        	                    // Load saved ValidToken port. Event vector already set.
    in           	r11, res[r1]		                  // Do input and get port time/timestamps
    getts	       	r11, res[r1]
    ldw                 r9, dp[g_txHandshakeTimeout]
    add          	r11, r11, r9
    setpt	       	res[r1], r11		                  // Set port time and enable events
    eeu	       	res[r1]

WaitForHandshake:			                            // Wait for timeout or handshake
    .xtabranch TxHandshakeTimeOut, TxHandShakeReceived
    waiteu


// We sent some data but the host didn't handshake in time.  Needs a re-send.
.align 4
TxHandshakeTimeOut:
    in 	    	r11, res[r1]                    // This will clear port time
    edu         res[r1]
    ldc         r11, 1
    out         res[r5], r11        
    bu        	NextToken

// Transmitted data, and got something back within the timeout. Check for valid handshake...
.align 4
TxHandShakeReceived:
XUD_IN_RxAck:
    in 		    r11, res[RXD]                   // Input data from RXD port
    clrpt		res[r1]			                // Clear port time on valid token port
    shr         r11, r11, 24                    // Shift off junk data to leave ACK
#ifdef ARCH_L
    ldc         r9, PID_ACK                     // Check for good ACK (L series strips of negated bits from PID)
#else
    ldc         r9, PIDn_ACK        
#endif  
    xor         r9, r11, r9
    edu         res[r1]                         // Disable events on ValidToken port        
    bt          r9, BadHandShake                // Invalid handshake received from host. we need to resend...
   
DoneTx:
    ldap       r11, NextRxWord                  // Restore RXD event vector
    setv       res[RXD], r11
    ldc           r11, 0                        // Send 0 to EP thread for no error
    out           res[r5], r11
        
  bu        	NextToken

BadHandShake:				                            // Received a bad handshake
    ldc           r11, 1                                      // Send 1 for error
    out           res[r5], r11
        
    bu 		NextToken

.align 32
.skip 26
SmallTxPacket:
//    inct       r8, res[r5]                      // Input tail length + 10
    inct       r6, res[r5]                      // get end of packet token
    //sub        r8, r8, 10
    in         r6, res[r5]                      // Input tail data
    //shl        r8, r8, 4                        // Tail length bytes to bits *2

//    shr        r8, r8, 1
        
    .xtabranch TxTail0s, TxTail1s, TxTail2s, TxTail3s
    bru       r8                                // branch taillength

//--------------------------------------------------------------------------
.align 64
.skip 0
TxTail0s:                                       // We know this is a < 4 byte packet, so is 0 length packet
                                                // So crc = 0. Note our normal crc calculation works for this, it is 
                                                //not a special CRC case, but helps with timing.
    ldc        r8, 0        
XUD_IN_TxPid_TailS0:
    outpw      res[TXD], r11, 8                 // PID
    //crc32    r7, r11, r9                      // r11: 0
    //not      r7, r7

XUD_IN_TxCrc_TailS0:
    outpw      res[TXD], r8, 16                 // r5: 0
    bu         DoneTail

.align 64
.skip 0
TxTail1s:
    ldc        	r8, 0               
    // One tail byte
    shl 		r6, r6, 8
    or  		r11, r11, r6
    shr 		r6, r6, 8
    crc8        r7, r4, r6, r9        
    crc32       r7, r8, r9               		// r5: 0 
    not         r7, r7        

XUD_IN_TxPid_TailS1:
    outpw     	res[TXD], r11, 16        		// PID
    ///outpw       res[TXD], r6, 16
XUD_IN_TxCrc_TailS1:
    outpw       res[TXD], r7, 16
    bu           DoneTail

.align 64
.skip 0
TxTail2s:
    ldc        r8, 0           
    // Two tail byte    
    shl     r6, r6, 8
    or      r11, r11, r6
    shr     r6, r6, 8
//    outpw     res[TXD], r11, 8        // PID
//    outpw        res[TXD], r6, 16

    crc8         r7, r6, r6, r9
    crc8         r7, r6, r6, r9
    crc32        r7, r8, r9               // r5: 0     
    not          r7, r7
    shr        r6, r7, 8
    
    shl        r7, r7, 24
    zext       r11, 24
    or         r11, r11, r7
XUD_IN_TxPid_TailS2:
    out     res[TXD], r11        
//    outpw        res[TXD], r7, 16

XUD_IN_TxCrc_TailS2:
    outpw      res[TXD], r6, 8
    bu           DoneTail

.align 64
.skip 0
TxTail3s:
    ldc        r8, 0           
	// Two tail byte 
XUD_IN_TxPid_TailS3:
  outpw        res[TXD], r11, 8         // PID
  outpw        res[TXD], r6, 24
  crc8         r7, r6, r6, r9
  crc8         r7, r6, r6, r9
  crc8         r7, r6, r6, r9
	
  crc32        r7, r8, r9               // r5: 0     
  not          r7, r7

XUD_IN_TxCrc_TailS3:
  outpw        res[TXD], r7, 16
  bu           DoneTail
.cc_bottom Pid_In.func

.globl XUD_InReady_Buffer
.cc_top XUD_InReady_Buffer.func, XUD_InReady_Buffer
// Specific IN code for L1 USB Audio Feedback EP (ep1_in)
// This sends fixed length (4 bytes) packet, reading the feedback value from memory.
// The event vector for the channel is set to this code, and data is never read from
// the channel so that the event will always be taken.
.align 4
XUD_InReady_Buffer:     
    //TODO LOOKUP EP TYPE
    clre                                        // Endpoint has data to send 
    //in         r11, res[r5]
    //chkct       res[r5], XS1_CT_END
    //out		     res[r5], r10                     // Reply to request to send

    
    
//PidToggle:
    //ld8u       r11, r6[r10]                     // Load data pid from table
    //ldc        r7, 0x88
    //xor        r8, r11, r7
    //st8        r8, r6[r10]
    
	ldc			r11, PIDn_DATA0
    ldc        r7, 0xf335                       // Init CRC

//NormalTxPacket:
//SendDataPid1:
	
	  ldw        r6, dp[Endpoint1_feedback_buffer] //in				r6, res[r5]                       // Get data word (loop unrolled once)
	  crc32      r7, r6, r9
	  
    outpw      res[TXD], r11, 8                 // Output PID to bus
    
    out        res[TXD], r6 

    crc32        r7, r3, r9                 // r3: 0
    not          r7, r7
    outpw        res[TXD], r7, 16

    bu           DoneTail  
       

.cc_bottom XUD_InReady_Buffer.func

.globl XUD_InReady_Buffer_3Byte
.cc_top XUD_InReady_Buffer_3Byte.func, XUD_InReady_Buffer_3Byte
// Specific IN code for L1 USB Audio Feedback EP (ep1_in)
// This sends fixed length (**3** bytes) packet, reading the feedback value from memory.
// The event vector for the channel is set to this code, and data is never read from
// the channel so that the event will always be taken.
.align 4
XUD_InReady_Buffer_3Byte:     
    //TODO LOOKUP EP TYPE
    clre                                        // Endpoint has data to send 
    
	ldc			r11, PIDn_DATA0
    
    ldc        r7, 0xf335                       // Init CRC

	ldw        r6, dp[Endpoint1_feedback_buffer] //in				r6, res[r5]                       // Get data word (loop unrolled once)
    ldc        r5, 0	  
    

    // Two tail byte 
    outpw        res[TXD], r11, 8     // PID
    outpw        res[TXD], r6, 24
    crc8         r7, r6, r6, r9
    crc8         r7, r6, r6, r9
    crc8         r7, r6, r6, r9

    crc32        r7, r5, r9               // r5: 0     
    not          r7, r7
    outpw        res[TXD], r7, 16
    bu           DoneTail
        
.cc_bottom XUD_InReady_Buffer_3Byte.func
