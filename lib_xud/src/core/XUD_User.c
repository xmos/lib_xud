// Copyright 2011-2023 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

/* User functions to be overridden by app */
#include "xud.h"

void XUD_UserSuspend(void) __attribute__ ((weak));
void XUD_UserSuspend()
{
    return;
}

void XUD_UserResume(void) __attribute__ ((weak));
void XUD_UserResume()
{
    return;
}



