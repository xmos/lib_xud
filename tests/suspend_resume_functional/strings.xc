// Copyright 2018-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include <stdio.h>
#include "strings.h"

void describe_galaxian_access(char s[128], unsigned reg, unsigned data)
{
  s[0] = '\0';
  if (reg == 0x50) {
    if (data == 0x8)
      sprintf(s, "enable clock");
    else if (data == 0xC)
      sprintf(s, "enable clock, enter active mode");
  }
}

void describe_phy_access(char s[128], unsigned reg, unsigned data)
{
  s[0] = '\0';
  switch (reg) {
    case 0x04:
      if (data == 0x4) {
        sprintf(s, "linestate decode mode");
      }
      else if (data == 0x47) {
        sprintf(s, "tokens mode including SOF with linestate decode");
      }
      break;
    case 0x08:
      sprintf(s, "default device address");
      break;
    case 0x0C:
      if (data == 0x3) {
        sprintf(s, "full-speed termination (TERMSELECT, XCVRSELECT)");
      }
      break;
    case 0x10:
      if (data == 0) {
        sprintf(s, "clear OTG flags");
      }
      break;
    case 0x14:
      if (data == 0x20) {
        sprintf(s, "OTG flags: SESSVLDB");
      }
      break;
    case 0x24:
      if (data == 0x00201008) {
        sprintf(s, "flag0 to J, flag1 to K, flag2 to SE0");
      }
      else if (data == 0x00010240) {
        sprintf(s, "flag0 to RxError, flag1 to RxActive, flag2 to new token");
      }
      break;
    case 0x40:
      if (data == 0) {
        sprintf(s, "reset PHY");
      }
      break;
    case 0x4C:
      sprintf(s, "tuning settings");
      break;
  }
}
