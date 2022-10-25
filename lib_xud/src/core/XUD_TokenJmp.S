// Copyright 2013-2022 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#if defined(__XS2A__)
    ldaw       r10, dp[PidJumpTable]                  // TODO Could load from sp here
                                                      // We receive: | 0000 4-bit EP | 0000 4-bit PID |
    inpw       r11, res[RXD], 8                       // Read 8 bit PID
    shr        r11, r11, 24                           // Shift off junk

    ldw        r10, r10[r11]                          // Load relevant branch address
    bau        r10
#else
    {ldw         r10, sp[STACK_PIDJUMPTABLE]
    ldc         r8, 16}

    inpw        r11, res[RXD], 8                       // Read 3 byte token from data port | CRC[5] | EP[4] | ADDR[7] | PID[8] | junk
    {setpsc      res[RXD], r8; shr      r11, r11, 24}

    ldw         r11, r10[r11]
    bau         r11                                    // Branch to Pid_Out, Pid_Sof, Pid_In, Pid_Setup etc

#endif

