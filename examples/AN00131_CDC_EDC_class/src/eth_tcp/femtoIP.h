// Copyright 2015-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#ifndef _FEMTOIP_H_
#define _FEMTOIP_H_

void patchIPHeader(unsigned int packet[], int to, int packetLength, int isTCP);

#endif
