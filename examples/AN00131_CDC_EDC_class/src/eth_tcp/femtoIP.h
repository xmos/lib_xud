// Copyright (c) 2015-2017, XMOS Ltd, All rights reserved

#ifndef _FEMTOIP_H_
#define _FEMTOIP_H_

void patchIPHeader(unsigned int packet[], int to, int packetLength, int isTCP);

#endif
