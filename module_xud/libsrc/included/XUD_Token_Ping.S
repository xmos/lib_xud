// r10: EP number
// PING -----------------------------------------------------------------------------

.align 4
.skip 0
    .cc_top Pid_Ping.func, Pid_Ping
Pid_Ping:
#ifdef ARCH_L        
    inpw      r10, res[RXD], 8;                        /* Read EP Number */ 
    shr       r10, r10, 24;                            /* Shift off junk */  

    in         r11, res[r1];  
    bf         r11, InvalidToken;                       /* If VALID_TOKEN not high, ignore token */
#else
    #include "XUD_G_Crc.S"                       
#endif

LoadStatTablePing:
    ldw       r5, r5[r10]                       // Load relevant EP chanend
    bf        r5, PrimaryBufferFull_PING
  
PrimaryBufferEmpty_PING:               // Send ACK
  nop
  nop
  ldc          r11, PIDn_ACK
  outpw        res[TXD], r11, 8
  bu           Return_PING 


PrimaryBufferFull_PING:
  nop
  nop
  ldc          r11, PIDn_NAK
  outpw        res[TXD], r11, 8
  bu           Return_PING

Return_PING:
  bu NextTokenAfterPing
 
    .cc_bottom Pid_Ping.func
