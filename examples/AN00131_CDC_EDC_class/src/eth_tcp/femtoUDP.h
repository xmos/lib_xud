// Copyright 2015-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#ifndef _FEMTOUDP_H_
#define _FEMTOUDP_H_

void patchUDPHeader(unsigned int packet[], int packetHighestByteIndex, int to, int srcPortRev, int dstPortRev);

#endif
