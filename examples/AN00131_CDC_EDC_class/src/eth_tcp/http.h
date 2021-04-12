// Copyright 2015-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#ifndef _HTTP_H_
#define _HTTP_H_

void httpProcess(unsigned int packet[], int charOffset, int packetLength, unsigned int rsp_packet[], unsigned &rsp_len);

#endif
