// Copyright 2011-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#ifndef __XUD_TESTMODE_H__
#define __XUD_TESTMODE_H__

#include <xs1.h>
#include <print.h>

#include "XUD_UIFM_Functions.h"
#include "XUD_UIFM_Defines.h"
#include "XUD_USB_Defines.h"
#include "XUD_Support.h"

unsigned UsbTestModeHandler_asm();
unsigned XUD_UsbTestSE0();

int XUD_TestMode_TestJ () ;
int XUD_TestMode_TestK () ;
int XUD_TestMode_TestSE0NAK () ;
int XUD_TestMode_TestPacket () ;

#endif
