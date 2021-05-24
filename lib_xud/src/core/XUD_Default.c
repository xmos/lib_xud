// Copyright 2019-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include "xud.h"

#if defined(__XS3A__)
unsigned int XUD_HAL_GetVBusState(void) __attribute__((weak));
#else
unsigned int read_vbus();
#endif

unsigned int XUD_HAL_GetVBusState(void)
{
#if defined(__XS3A__)
    return 1u;
#elif defined(__XS2A__)
    return read_vbus();
#else
#error no architecture defined
#endif
}
