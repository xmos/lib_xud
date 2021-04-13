// Copyright 2015-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
/** @file      XUD_GetDone.c
  * @author    Matt Fyles, XMOS Limited
  * @version   1v0
  */

extern int XUD_USB_Done;

int XUD_GetDone() {
  return XUD_USB_Done;
}


