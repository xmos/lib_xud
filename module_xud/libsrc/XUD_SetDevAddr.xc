
#include "XUD_UIFM_Functions.h"
#include "XUD_USB_Defines.h"
#include "XUD_UIFM_Defines.h"
#ifdef ARCH_S
#include <xa1_registers.h>
#include <print.h>
#include "glx.h"
extern unsigned get_tile_id(tileref ref);
extern tileref xs1_su_periph;
#endif


void XUD_SetCrcTableAddr(unsigned addr);

/** @brief  Sets the device addres in XUD 
  * @param  addr the new address
  */ 
void XUD_SetDevAddr(unsigned addr)
{
#ifdef ARCH_S
    unsigned data;
#endif

#ifdef ARCH_L
    /* Set device address in UIFM */
#ifdef ARCH_S
    write_glx_periph_word(get_tile_id(xs1_su_periph), XS1_GLX_PERIPH_USB_ID, XS1_UIFM_DEVICE_ADDRESS_REG, addr);
    read_glx_periph_word(get_tile_id(xs1_su_periph), XS1_GLX_PERIPH_USB_ID, XS1_UIFM_DEVICE_ADDRESS_REG, data);
#else
    /* RegWrite_ loads write port from dp to avoid parallel usage checks */
    /* TODO this should really be locked for mutual exclusion */
    XUD_UIFM_RegWrite_(UIFM_REG_ADDRESS, addr);
#endif

#elif ARCH_G
    /* Modify CRC table for current address */
    XUD_SetCrcTableAddr(addr);
#else
#error ARCH_L or ARCH_G MUST be defined 
#endif

}
