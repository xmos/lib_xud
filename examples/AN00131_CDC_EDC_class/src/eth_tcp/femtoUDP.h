// Copyright (c) 2015-2017, XMOS Ltd, All rights reserved

#ifndef _FEMTOUDP_H_
#define _FEMTOUDP_H_

void patchUDPHeader(unsigned int packet[], int packetHighestByteIndex, int to, int srcPortRev, int dstPortRev);

#endif
