// Copyright (c) 2015-2016, XMOS Ltd, All rights reserved

#ifndef _FEMTOTCP_H_
#define _FEMTOTCP_H_

void processTCPPacket(unsigned int packet[], unsigned len, unsigned int rsp_packet[], unsigned &rsp_len);

void tcpString(char s[], unsigned int rsp_packet[], unsigned &rsp_len);

#endif
