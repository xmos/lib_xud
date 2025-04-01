// Copyright 2011-2025 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#ifndef _XUD_SIGNALLING_H_
#define _XUD_SIGNALLING_H_
//void XUD_PhyReset(out port p_rst, int resetTime, unsigned rstMask);

enum SuspendState
{
    XUD_SUSPEND_STATE_NO_VBUS = -1,
    XUD_SUSPEND_STATE_RESET = 1,
    XUD_SUSPEND_STATE_RESUME_START = 2,
    XUD_SUSPEND_STATE_RESUME_END = 3,
};

int XUD_Init();

//int XUD_Suspend(XUD_PwrConfig pwrConfig);
int XUD_Suspend(XUD_PwrConfig pwrConfig, XUD_chan c[], XUD_chan epAddr_Ready[], XUD_EpType epTypeTableOut[], XUD_EpType epTypeTableIn[], int nOut, int nIn);
#endif
