
#include "XUD_UIFM_Functions.h"
#include "XUD_USB_Defines.h"
#include "XUD_UIFM_Defines.h"

void XUD_SetCrcTableAddr(unsigned addr);

/** @brief  Sets the device addres in XUD 
  * @param  addr the new address
  */ 
void XUD_SetDevAddr(unsigned addr)
{

#ifdef ARCH_L
    /* Set device address in UIFM */
    /* RegWrite_ loads write port from dp to avoid parallel usage checks */
    /* TODO this should really be locked for mutual exclusion */
    XUD_UIFM_RegWrite_(UIFM_REG_ADDRESS, addr);
#elif ARCH_G
    /* Modify CRC table for current address */
    XUD_SetCrcTableAddr(addr);
#else
#error ARCH_L or ARCH_G MUST be defined 
#endif

}
