// Copyright (c) 2011-2018, XMOS Ltd, All rights reserved

// On Entry:
//  r0: rxd port
//  r8: 16 (XS3 only)

// Required on exit:
//  r4: 0
// r10: Extracted EP number

#ifdef __XS3A__
#if 1 
    {in        r10, res[RXD];     sub      r1, r8, 5}    // ldc r1 11
    {shr       r10, r10, 16;      mkmsk    r11, r1}
    {and       r11, r10, r11;     shr      r4, r10, r1}  // r4: Received CRC

    ldaw       r8, dp[crc5Table_Addr]
    ld8u       r8, r8[r11]                               // Correct CRC

    xor        r4, r4, r8                                // R4 set to 0 in L code with in from valid tok port
    {BRFF_ru6  r4,  5;          shr        r10, r11, 7}  // Extract EP number
    
    ldw        r11, sp[STACK_RXA_PORT]                   // Wait for RXA to gow low (i.e. end of packet) 
    in         r10, res[r11]
    bt         r10, waitforRXALow0
    setc       res[RXD], XS1_SETC_RUN_CLRBUF
    bu         Loop_BadPid
#else
    in            r10, res[RXD]
    ldaw       r1, dp[crc5Table_Addr]
    ldc        r8, 30
    lmul       r11, r10, r10, r8, r10, r10               // r11 is CRC5, r10 is EP(4):ADDR(7):CRAP(16):0(5)
    shr        r10, r10, 16                              // r10 is 0(16):EP(4):ADDR(7):CRAP(5)
    shr        r10, r10, 5                               // r10 is 0(21):EP(4):ADDR(7)
    ld8u       r8, r1[r10]                               // r8 is CRC of r10
    sub        r4, r11, r8                               // R4 set to 0 in L code with in from valid tok port
    {BRFF_ru6  r4,  5;          shr        r10, r10, 7}  // Extract EP number

    ldw        r11, sp[STACK_RXA_PORT]                   // Wait for RXA to gow low (i.e. end of packet) 
    in         r10, res[r11]
    bt         r10, waitforRXALow0
    setc       res[RXD], XS1_SETC_RUN_CLRBUF
    bu         Loop_BadPid
#endif

#else 
    // __XS2A__
    inpw      r10, res[RXD], 8;                 // Read EP Number
    shr       r10, r10, 24;                     // Shift off junk

    in         r4, res[r1];
    bt         r4, XUD_InvalidToken;            // If VALID_TOKEN not high, ignore token - PORT INVERTED! */
#endif


