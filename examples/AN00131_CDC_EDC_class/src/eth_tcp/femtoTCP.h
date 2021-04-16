// Copyright 2015-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#ifndef _FEMTOTCP_H_
#define _FEMTOTCP_H_

void processTCPPacket(unsigned int packet[], unsigned len, unsigned int rsp_packet[], unsigned &rsp_len);

void tcpString(char s[], unsigned int rsp_packet[], unsigned &rsp_len);

#endif
