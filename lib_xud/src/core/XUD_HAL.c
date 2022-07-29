// Copyright 2019-2022 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

/* See XUD_HAL.xc */
unsigned int XUD_HAL_GetVBusState_(void);
unsigned int XUD_HAL_GetVBusState(void) __attribute__((weak));

unsigned int XUD_HAL_GetVBusState(void)
{
    return XUD_HAL_GetVBusState_();
}
