//CrcAddrCheck:                                           // Extract 11 bits for CRC5: | EP(4) | ADDR(7) |
    in          r10, res[RXD]
    shr         r10, r10, 16
    and         r6, r10, r6  
    ld8u        r8, r8[r6]                              // Correct CRC 
    shr         r6, r10, 5                          
    shr         r6, r6, 6                               // Received CRC
    eq          r6, r6, r8
    bf          r6,  BadCrcAddr                          

//ExtractEP:  
    shr         r10, r10, 7
    zext        r10,  4    
