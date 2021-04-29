// Copyright 2019-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#if defined(__XS3A__)
unsigned int XUD_HAL_GetVBusState(void) __attribute__((weak));
#endif
unsigned int XUD_HAL_GetVBusState(void)
{
#if defined(__XS3A__)
    return 1u;
#elif defined(__XS2A__)
    unsigned int x;

    read_periph_word(USB_TILE_REF, XS1_GLX_PER_UIFM_CHANEND_NUM, XS1_GLX_PER_UIFM_OTG_FLAGS_NUM, x);

    return x & (1 << XS1_UIFM_OTG_FLAGS_SESSVLDB_SHIFT);
#else
#error no architecture defined
#endif
}
