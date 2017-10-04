// Copyright (c) 2015-2016, XMOS Ltd, All rights reserved

#ifndef _HTTP_H_
#define _HTTP_H_

void httpProcess(unsigned int packet[], int charOffset, int packetLength, unsigned int rsp_packet[], unsigned &rsp_len);

#endif
