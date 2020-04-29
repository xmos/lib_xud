#if 0
#pragma xta command "config threads stdcore[0] 6"
#pragma xta command "add exclusion Pid_Out"
#pragma xta command "add exclusion Pid_Setup"
#pragma xta command "add exclusion Pid_Sof"
#pragma xta command "add exclusion Pid_Reserved"
#pragma xta command "add exclusion Pid_Ack"
#pragma xta command "add exclusion Pid_Data0"
#pragma xta command "add exclusion Pid_Ping"
#pragma xta command "add exclusion Pid_Nyet"
#pragma xta command "add exclusion Pid_Data2"
#pragma xta command "add exclusion Pid_Data1"
#pragma xta command "add exclusion Pid_Data0"
#pragma xta command "add exclusion Pid_Datam"
#pragma xta command "add exclusion Pid_Split"
#pragma xta command "add exclusion Pid_Stall"
#pragma xta command "add exclusion Pid_Pre"
#pragma xta command "add exclusion InvalidToken"
#pragma xta command "add exclusion InReady"

#pragma xta command "analyse path XUD_TokenRx_Pid XUD_TokenRx_Ep"
#pragma xta command "set required - 33 ns"
#endif


/* Rx to TX 16 clks required with SMSC phy (14 in spec).  SIE Decision Time */
#if 0
#pragma xta command "analyse path XUD_TokenRx_Ep XUD_IN_TxNak"
#pragma xta command "set required - 233 ns"
#pragma xta command "add exclusion InNotReady"
#pragma xta command "remove exclusion InReady"


#pragma xta command "add exclusion XUD_IN_TxPid_Tail1"
#pragma xta command "add exclusion XUD_IN_TxPid_Tail2"
#pragma xta command "add exclusion XUD_IN_TxPid_Tail3"
#pragma xta command "add exclusion XUD_IN_TxPid_TailS0"
#pragma xta command "add exclusion XUD_IN_TxPid_TailS1"
#pragma xta command "add exclusion XUD_IN_TxPid_TailS2"
#pragma xta command "add exclusion XUD_IN_TxPid_TailS3"
#endif
#if 0
#pragma xta command "analyse path XUD_TokenRx_Ep XUD_IN_TxPid_Tail0"
#pragma xta command "set required - 266 ns"
#endif

#if 0
#pragma xta command "remove exclusion XUD_IN_TxPid_TailS0"
#pragma xta command "add exclusion XUD_IN_TxPid_Tail0"
#pragma xta command "analyse path XUD_TokenRx_Ep XUD_IN_TxPid_TailS0"
#pragma xta command "set required - 266 ns"

#pragma xta command "remove exclusion XUD_IN_TxPid_Tail1"
#pragma xta command "add exclusion XUD_IN_TxPid_TailS0"
#if 0
#pragma xta command "analyse path XUD_TokenRx_Ep XUD_IN_TxPid_Tail1"
#pragma xta command "set required - 266 ns"
#endif

#pragma xta command "remove exclusion XUD_IN_TxPid_TailS1"
#pragma xta command "add exclusion XUD_IN_TxPid_Tail1"
#if 0
#pragma xta command "analyse path XUD_TokenRx_Ep XUD_IN_TxPid_TailS1"
#pragma xta command "set required - 266 ns"
#endif

//#pragma xta command "remove exclusion ShortPacket"
//pragma xta command "add exclusion NormalPacket"
//#pragma xta command "analyse path XUD_TokenRx_Ep XUD_IN_TxPid_Short"
//#pragma xta command "set required - 233 ns"

/* TX TO RX */
/* Tx IN NAK to Token Rx */
#pragma xta command "remove exclusion InNotReady"
#pragma xta command "add exclusion InReady"
#if 0
#pragma xta command "analyse path XUD_TokenRx_Pid XUD_IN_TxNak"
#pragma xta command "set required - 100 ns"
#endif

/* Tx OUT NAK to Token RX */
#if 0
#pragma xta command "analyse path XUD_OUT_TxNak XUD_TokenRx_Pid"
#pragma xta command "set required - 100 ns"
#endif

/* Tx OUT ACK to Token Tx */
#if 0
#pragma xta command "analyse path XUD_OUT_TxAck XUD_TokenRx_Pid"
#pragma xta command "set required - 100 ns"
#endif

/* Tx IN Data (so crc) to Rx Ack (Non ISO IN) */
#pragma xta command "add exclusion InNotReady"
#pragma xta command "remove exclusion InReady"
#if 0
#pragma xta command "add exclusion InISO"
#pragma xta command "add exclusion TxHandshakeTimeOut"
#endif

#pragma xta command "remove exclusion XUD_IN_TxPid_Tail0"
#pragma xta command "add exclusion XUD_IN_TxPid_TailS1"
#if 0
#pragma xta command "analyse path XUD_IN_TxCrc_Tail0 XUD_IN_RxAck"
#pragma xta command "set required - 100 ns"
#endif

#pragma xta command "add exclusion XUD_IN_TxPid_Tail0"
#pragma xta command "remove exclusion XUD_IN_TxPid_Tail1"
#if 0
#pragma xta command "analyse path XUD_IN_TxCrc_Tail1 XUD_IN_RxAck"
#pragma xta command "set required - 100 ns"
#endif

#pragma xta command "add exclusion XUD_IN_TxPid_Tail1"
#pragma xta command "remove exclusion XUD_IN_TxPid_TailS0"
#if 0
#pragma xta command "analyse path XUD_IN_TxCrc_TailS0 XUD_IN_RxAck"
#pragma xta command "set required - 100 ns"
#endif

#pragma xta command "add exclusion XUD_IN_TxPid_TailS0"
#pragma xta command "remove exclusion XUD_IN_TxPid_TailS1"
#if 0
#pragma xta command "analyse path XUD_IN_TxCrc_TailS1 XUD_IN_RxAck"
#pragma xta command "set required - 100 ns"
#endif

/* Tx IN Data (so crc) to Rx Token PID (ISO In) */
#pragma xta command "remove exclusion InISO"
#pragma xta command "add exclusion InNonISO"

#if 0
#pragma xta command "analyse path XUD_IN_TxCrc_Tail0 XUD_TokenRx_Pid"
#pragma xta command "set required - 100 ns"

#pragma xta command "analyse path XUD_IN_TxCrc_Tail1 XUD_TokenRx_Pid"
#pragma xta command "set required - 100 ns"

#pragma xta command "analyse path XUD_IN_TxCrc_Tail2 XUD_TokenRx_Pid"
#pragma xta command "set required - 100 ns"

#pragma xta command "analyse path XUD_IN_TxCrc_Tail3 XUD_TokenRx_Pid"
#pragma xta command "set required - 100 ns"

#pragma xta command "analyse path XUD_IN_TxCrc_TailS0 XUD_TokenRx_Pid"
#pragma xta command "set required - 100 ns"

#pragma xta command "analyse path XUD_IN_TxCrc_TailS1 XUD_TokenRx_Pid"
#pragma xta command "set required - 100 ns"

#pragma xta command "analyse path XUD_IN_TxCrc_TailS2 XUD_TokenRx_Pid"
#pragma xta command "set required - 100 ns"

#pragma xta command "analyse path XUD_IN_TxCrc_TailS3 XUD_TokenRx_Pid"
#pragma xta command "set required - 100 ns"
#endif

/* RX TO RX */
/* Rx SOF to Rx SOF - This is a non-interesting case since timing will be ~125uS */

//#pragma xta command "remove exclusion Pid_Sof"
//#pragma xta command "add exclusion Pid_Out"
//#pragma xta command "add exclusion Pid_In"
#if 0
#pragma xta command "analyse path XUD_TokenRx_Ep XUD_TokenRx_Pid"
#pragma xta command "set required - 50 ns"
#endif

/* Rx OUT Data end to Rx Token (ISO Out Data) */
//#pragma xta command "add exclusion OutTail0"
//#pragma xta command "add exclusion OutTail1"
//#pragma xta command "add exclusion OutTail2"
//#pragma xta command "add exclusion OutTail3"
//#pragma xta command "add exclusion OutTail4"
//#pragma xta command "add exclusion OutTail5"
//#pragma xta command "add exclusion ReportBadCrc"
//#pragma xta command "add exclusion DoOutHandShakeOut"
#if 0
#pragma xta command "analyse path XUD_OUT_RxTail XUD_TokenRx_Pid"
#pragma xta command "set required - 50 ns"
#endif


#endif
/* TX INTRA PACKET TIMING */
#if 0
#pragma xta command "analyse path XUD_IN_TxPid_Tail0 TxLoop0_Out"
#pragma xta command "set required - 83 ns"
#endif

