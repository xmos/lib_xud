// Copyright 2013-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#ifdef ARCH_L
    ldaw        r10, dp[PidJumpTable]                 // TODO Could load from sp here
                                                      // We receive: | 0000 4-bit EP | 0000 4-bit PID |
    inpw       r11, res[RXD], 8                       // Read 8 bit PID
    shr        r11, r11, 24                           // Shift off junk

    ldw        r10, r10[r11]                          // Load relevant branch address

.xtabranch  Pid_Out, Pid_Sof, Pid_In, Pid_Setup, Pid_Sof_NoChan
    bau        r10
#else // ARCH_G
    //ldaw        r8, dp[crc5Table_Addr]
    ldaw        r10, dp[PidJumpTable]
    //ldw         r6, dp[crcmask]
    ldc         r8, 16

    inpw        r11, res[RXD], 8                       // Read 3 byte token from data port | CRC[5] | EP[4] | ADDR[7] | PID[8] | junk
    setpsc      res[RXD], r8
    shr         r11, r11, 24

    ldw         r11, r10[r11]
.xtabranch  Pid_Out, Pid_Sof, Pid_In, Pid_Setup
    bau         r11
#endif

