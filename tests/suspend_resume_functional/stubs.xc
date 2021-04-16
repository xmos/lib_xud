// Copyright 2018-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include <stdio.h>
#include <assert.h>
#include "xud.h"

typedef unsigned XUD_chan;

void XUD_Sup_Delay(unsigned delay)
{
  // nothing
}

unsigned XUD_EnableUsbPortMux(void)
{
  return 0;
}

int XUD_GetDone(void)
{
  return 0;
}

unsigned XUD_Sup_GetResourceId(chanend c)
{
  return 0;
}

int test_read_sswitch_reg(unsigned tileid, unsigned reg, unsigned &data)
{
  assert(0);
  return -1;
}
