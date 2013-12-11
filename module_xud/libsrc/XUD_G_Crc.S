//CrcAddrCheck:                                           // Extract 11 bits for CRC5: | EP(4) | ADDR(7) |
    in          r10, res[RXD]
    shr         r10, r10, 16
    ldw         r11, dp[crcmask]
    and         r11, r10, r11
    ldaw         r8, dp[crc5Table_Addr] 
    ld8u        r8, r8[r11]                              // Correct CRC
    
    shr         r6, r10, 5
    shr         r6, r6, 6                               // Received CRC
    eq          r6, r6, r8
    bf          r6,  BadCrcAddr

//ExtractEP:
    shr         r10, r10, 7
    zext        r10,  4
    ldc         r4, 0                                   // R4 set to 0 in L code with in from valid tok port
    ldc         r6, 0x3334
