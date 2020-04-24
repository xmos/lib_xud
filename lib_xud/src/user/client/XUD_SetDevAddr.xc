// Copyright (c) 2011-2018, XMOS Ltd, All rights reserved

#include "XUD_UIFM_Functions.h"
#include "XUD_USB_Defines.h"
#include "xud.h"

#if defined(__XS2A__)
#include "xs2_su_registers.h"
#include "XUD_USBTile_Support.h"
extern unsigned get_tile_id(tileref ref);
extern tileref USB_TILE_REF;
#endif

void XUD_SetCrcTableAddr(unsigned addr);

/** @brief  Sets the device addres in XUD
  * @param  addr the new address
  */
XUD_Result_t XUD_SetDevAddr(unsigned addr)
{
    /* Set device address in UIFM */
#if defined(__XS2A__)
        write_periph_word(USB_TILE_REF, XS1_GLX_PER_UIFM_CHANEND_NUM, XS1_GLX_PER_UIFM_DEVICE_ADDRESS_NUM, addr);
#elif defined(__XS1B__)
    #if defined(ARCH_S)
        write_periph_word(USB_TILE_REF, XS1_SU_PER_UIFM_CHANEND_NUM, XS1_SU_PER_UIFM_DEVICE_ADDRESS_NUM, addr);
    #else
            /* Vanilla XS1B/XS1-L */
            /* RegWrite_ loads write port from dp to avoid parallel usage checks */
            /* TODO this should really be locked for mutual exclusion */
            XUD_UIFM_RegWrite_(UIFM_REG_ADDRESS, addr);
    #endif
    #elif defined(__XS1A__) || defined (__XS3A__)
        /* XS1A (XS1-G) and XS3: Modify CRC table for current address */
        XUD_SetCrcTableAddr(addr);
#else
    #error ARCH define error
#endif

    return XUD_RES_OKAY;
}
