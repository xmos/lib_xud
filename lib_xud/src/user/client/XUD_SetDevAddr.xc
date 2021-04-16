// Copyright 2011-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#include "xud.h"
#include "XUD_HAL.h"

void XUD_SetCrcTableAddr(unsigned addr);

/** @brief  Sets the device addres in XUD
  * @param  addr the new address
  */
XUD_Result_t XUD_SetDevAddr(unsigned addr)
{
#ifdef __XS3A__        
    /* XS1A (XS1-G) and XS3: Modify CRC table for current address */
    XUD_SetCrcTableAddr(addr);
#else
    /* Set device address in UIFM */
    write_periph_word(USB_TILE_REF, XS1_GLX_PER_UIFM_CHANEND_NUM, XS1_GLX_PER_UIFM_DEVICE_ADDRESS_NUM, addr);
#endif
    return XUD_RES_OKAY;
}
