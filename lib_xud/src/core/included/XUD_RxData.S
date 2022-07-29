// Copyright 2019-2022 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#define PASTER(x,y) x ## _ ## y
#define EVALUATOR(x,y)  PASTER(x,y)
#define LABEL(fun) fun

// r0: RXD: Rx Data port
// r1: Buffer
// r2: Tx Port
// r3: Ep structure
// r4: Zero (set in XUD_CrcAddCheck.S) then buffer index
// r5: EP structures array
// r6: CRC Rx init
// r7: CRC Tx init
// r9: CRC poly
// r8: Scratch
// r10: EP number
// r11: Scratch

// On exit require:
// r4: Datalength (words)
// r8: Taillength (bits)
// r11: Expected CRC

Pid_Bad_RxData:
    ldaw      r10, dp[PidJumpTable]
    {ldw      r11, r10[r4];         ldc r8, 16}
    {bau      r11;                  setpsc      res[RXD], r8}   // XUD_CrcAddrCheck.S requires 16 in r8

doRXData:
    inpw        r4, res[r0], 8                                  // Input PID

    ldw         r8, sp[STACK_RXA_PORT]
#ifdef __XS2A__
    // If pid != DATAx then jump and handle as a token. DATA0, DATA1, DATA2 & MDATA all of the form 0bxx11.
    // This is a fast alternative to a "timeout"
    // Note, this doesn't check that PID[0:3] = ~PID[4:7] - which is an issue for XS3
    {mkmsk r11, 2;                  shr         r4, r4, 24}
    and         r11, r11, r4                                    // Store PID into EP structure,
    eq          r11, r11, 3
    bf          r11, Pid_Bad_RxData
#else
    {shr        r4, r4, 24;         ldw     r11, sp[STACK_PIDJUMPTABLE_RXDATA]}
    ldw         r11, r11[r4]
    bau         r11
#endif

Pid_Datam_RxData:
Pid_Data0_RxData:
Pid_Data1_RxData:
Pid_Data2_RxData:
    {stw         r4, r3[6];         setsr 1}                    // Store PID into EP structure

GotRxPid:
    {eeu        res[r8];            mkmsk r4, 32}               // Enable events on RxA
                                                                // Init buffer index to -1

NextRxWord:				                                        // Partially un-rolled to assist with timing
    in          r11, res[r0]
    crc32_inc   r6, r11, r9, r4, 1
    stw         r11, r1[r4]
    in 	        r11, res[r0]
    crc32_inc   r6, r11, r9, r4, 1
    stw         r11, r1[r4]
    in 	        r11, res[r0]
    crc32_inc   r6, r11, r9, r4, 1
    stw         r11, r1[r4]
    in 	        r11, res[r0]
    crc32_inc   r6, r11, r9, r4, 1
    stw         r11, r1[r4]
    in 	        r11, res[r0]
    crc32_inc   r6, r11, r9, r4, 1
    stw         r11, r1[r4]
    in 	        r11, res[r0]
    crc32_inc   r6, r11, r9, r4, 1
    stw         r11, r1[r4]
    in 	        r11, res[r0]
    crc32_inc   r6, r11, r9, r4, 1
    stw         r11, r1[r4]
    in 	        r11, res[r0]
    crc32_inc   r6, r11, r9, r4, 1
    stw         r11, r1[r4]
    in 	        r11, res[r0]
    crc32_inc   r6, r11, r9, r4, 1
    stw         r11, r1[r4]
    bu          NextRxWord

/////////////////////////////////////////////////////////////////////////////
.align 32
.skip 16
RxALow:
    stw         r11, r1[r4]                                 // Extra stw, if not enough MIPS STW in loop above may not have chance to run
    {in         r8, res[r8];        add r4, r4, 1}          // Clear event data on RXA
    endin       r8, res[r0]
LABEL(RxTail):
    {in          r11, res[r0];      bru      r8}

// Word aligned data (0 byte tail)
.align 32
OutTail0:
    crc32       r6, r8, r9                      // CRC zero step
    ldw         r11, sp[STACK_RXCRC_TAIL0]
    {RETSP_u6   0;  ldc r1, 0}

// 1 Tail Byte
.align 32
OutTail1:
    shr         r11, r11, 24                    // Shift off junk
    crc32       r6, r11, r9
    stw         r11, r1[r4]                     // Store last data
    LDWSP_ru6   r11, sp[STACK_RXCRC_TAIL1]
    {RETSP_u6   0;  ldc r1, 0}

// Two Tail Bytes
.align 32
OutTail2:
    shr         r11, r11, 16
    crc32       r6, r11, r9
    stw         r11, r1[r4]                      // Store last data
    ldw         r11, sp[STACK_RXCRC_TAIL2]
    {RETSP_u6   0;  ldc r1, 0}

// Three Tail Bytes
.align 32
OutTail3:
    shr         r11, r11, 8
    stw         r11, r1[r4]                     // Store last data
    crc32       r6, r11, r9
    LDWSP_ru6   r11, sp[STACK_RXCRC_TAIL3]
    crc8        r6, r1, r2, r9                  // Use the fact the the bottom byte of port id is 0.. saves us an ldc
    {RETSP_u6   0;  ldc r1, 0}

