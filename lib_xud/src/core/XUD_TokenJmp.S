// Copyright 2013-2025 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#if defined(__XS2A__)
    ldaw       r10, dp[PidJumpTable]                  // TODO Could load from sp here
                                                      // We receive: | 0000 4-bit EP | 0000 4-bit PID |
    inpw       r11, res[RXD], 8                       // Read 8 bit PID
    shr        r11, r11, 24                           // Shift off junk

    ldw        r10, r10[r11]                          // Load relevant branch address
    bau        r10
#undef XTA_TOKENJMP_PID
#undef XTA_TOKENJMP_EPCRC
#undef XTA_TOKENJMP_ID
#else
    {ldw         r10, sp[STACK_PIDJUMPTABLE]
    ldc         r8, 16}
XTA_TOKENJMP_PID:
#undef XTA_TOKENJMP_PID
    inpw        r11, res[RXD], 8                       // Read 3 byte token from data port | CRC[5] | EP[4] | ADDR[7] | PID[8] | junk
XTA_TOKENJMP_EPCRC:
#undef XTA_TOKENJMP_EPCRC
    {setpsc      res[RXD], r8; shr      r11, r11, 24}

    ldw         r11, r10[r11]
#define PASTER2(y,x)  xta_target ## y ## _ ## x
#define PASTER1(y,x)  PASTER2(y,x)
#define UNIQIFY(x)  PASTER1(XTA_TOKENJMP_ID,x)
UNIQIFY(Pid_Reserved):
UNIQIFY(Pid_Out):
UNIQIFY(Pid_Ack):
UNIQIFY(Pid_Data0):
UNIQIFY(Pid_Ping):
UNIQIFY(Pid_Sof):
UNIQIFY(Pid_Sof_NoChan):
UNIQIFY(Pid_Nyet):
UNIQIFY(Pid_Data2):
UNIQIFY(Pid_Split):
UNIQIFY(Pid_In):
UNIQIFY(Pid_Nak):
UNIQIFY(Pid_Data1):
UNIQIFY(Pid_Pre):
UNIQIFY(Pid_Setup):
UNIQIFY(Pid_Stall):
UNIQIFY(Pid_MData):
UNIQIFY(Pid_Bad):
#undef XTA_TOKENJMP_ID
    bau         r11                                    // Branch to Pid_Out, Pid_Sof, Pid_In, Pid_Setup etc

#endif

