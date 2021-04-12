// Copyright 2015-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#ifndef _DHCP_H_
#define _DHCP_H_

void processDHCPPacket(unsigned int packet[], unsigned len, unsigned int rsp_packet[], unsigned &rsp_len);

#endif
