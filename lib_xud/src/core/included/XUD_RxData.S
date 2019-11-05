

#define PASTER(x,y) x ## _ ## y
#define EVALUATOR(x,y)  PASTER(x,y)
//#define LABEL(fun) EVALUATOR(fun, LABELNO)
#define LABEL(fun) fun

// r0: RXD: Rx Data port
// r1: Buffer 
// r2: Tx Port 
// r3: Ep structure
// r4: zero
// r5: buffer address
// r5: ep structures array
// r6: crc rx init
// r7: crc tx init
// r9: crc poly
// r8: 
// r10: ep number
// r11: scratch

doRXData_badPid:
  ldc       r8, 16                                        // Note, this is a cut-down version of XUD_TokenJump.S
  ldaw      r10, dp[PidJumpTable]
  ldw       r11, r10[r7]
  {bau      r11;              setpsc      res[RXD], r8}

LABEL(doRXData):

    inpw       r8, res[r0], 8                               // Input PID

    // If pid != DATAx then jump and handle as a token. DATA0, DATA1, DATA2 & MDATA all of the form 0bxx11.
    // This is a fast alternative to a "timeout"
    {shr    r7, r8, 24;    mkmsk    r11, 2}
    and     r11, r11, r7
    eq      r11, r11, 3
    bf      r11, doRXData_badPid
    {setsr  1;             ldw      r7, sp[10]}             // Load RxA Port ID

LABEL(GotRxPid):
    eeu        res[r7]                                      // Enable events on RxA

LABEL(NextRxWord):				                                    
    in 	        r11, res[r0]
    stw         r11, r1[r4]
    crc32_inc   r6, r11, r9, r4, 1 
    in 	        r11, res[r0]
    stw         r11, r1[r4]
    crc32_inc   r6, r11, r9, r4, 1 
    in 	        r11, res[r0]
    stw         r11, r1[r4]
    crc32_inc   r6, r11, r9, r4, 1 
    in 	        r11, res[r0]
    stw         r11, r1[r4]
    crc32_inc   r6, r11, r9, r4, 1 
    bu          LABEL(NextRxWord)

/////////////////////////////////////////////////////////////////////////////
.align 32
.skip 20
RxALow:
    {stw       r8, r3[6];    in          r7, res[r7]}       // Store (NON-SHIFTED) PID into EP structure,
                                                            // Clear event data on RXA
    endin       r8, res[r0]
LABEL(RxTail):
    {in          r11, res[r0];      bru      r8}  

// Word aligned data (0 byte tail)
.align 32
OutTail0:
    crc32       r6, r8, r9                      // CRC zero step
    ldw         r11, sp[STACK_RXCRC_TAIL0]
    RETSP_u6   0

// 1 Tail Byte
.align 32
OutTail1:
    shr         r11, r11, 24                    // Shift off junk
    crc32       r6, r11, r9
    stw         r11, r1[r4]                     // Store last data
    LDWSP_ru6   r11, sp[STACK_RXCRC_TAIL1]
    RETSP_u6   0

// Two Tail Bytes
.align 32
OutTail2:
    shr         r11, r11, 16
    crc32       r6, r11, r9
    stw         r11, r1[r4]                      // Store last data
    ldw         r11, sp[STACK_RXCRC_TAIL2]
    RETSP_u6   0

// Three Tail Bytes
.align 32
OutTail3:
    shr         r11, r11, 8
    stw         r11, r1[r4]                     // Store last data
    crc32       r6, r11, r9
    LDWSP_ru6   r11, sp[STACK_RXCRC_TAIL3]
    crc8        r6, r1, r2, r9                  // Use the fact the the bottom byte of port id is 0.. saves us an ldc
    RETSP_u6   0

