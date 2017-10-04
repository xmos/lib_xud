// Copyright (c) 2015-2016, XMOS Ltd, All rights reserved

#ifndef _DHCP_H_
#define _DHCP_H_

void processDHCPPacket(unsigned int packet[], unsigned len, unsigned int rsp_packet[], unsigned &rsp_len);

#endif
