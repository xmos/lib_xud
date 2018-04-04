// Copyright (c) 2011-2018, XMOS Ltd, All rights reserved

#ifndef _XUD_PWRSIG_H_
#define _XUD_PWRSIG_H_
void XUD_PhyReset(out port p_rst, int resetTime, unsigned rstMask);

int XUD_Init();

int XUD_Suspend(XUD_PwrConfig pwrConfig);
#endif
