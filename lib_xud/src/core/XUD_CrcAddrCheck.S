// Copyright 2011-2024 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

// On Entry:
//  r0: rxd port
//  r8: 16 (XS3 only)

// Required on exit:
//  r4: 0
// r10: Extracted EP number

#if !defined(__XS2A__)
XTA_CRCADDRCHECK:
    {in        r10, res[RXD];     sub       r1, r8, 5}      // ldc r1 11
    {shr       r10, r10, 16;      mkmsk     r11, r1}
    {and       r11, r10, r11;     ldw       r8, sp[STACK_CRC5TABLE_ADDR]}

    {shr       r4, r10, r1                                  // r4: Received CRC
    ld8u       r8, r8[r11]}                                 // r8: Expected CRC

                                                            // R4 set to 0 in L code with in from valid tok port
    {eq         r4, r4, r8;        shr         r10, r11, 7} // Extract EP number
    bf          r4, XUD_InvalidToken

#undef XTA_CRCADDRCHECK
#else
    // __XS2A__
    inpw      r10, res[RXD], 8;                             // Read EP Number
    shr       r10, r10, 24;                                 // Shift off junk

    in         r4, res[r1];
    bt         r4, XUD_InvalidToken;                        // If VALID_TOKEN not high, ignore token - PORT INVERTED! */
#endif


