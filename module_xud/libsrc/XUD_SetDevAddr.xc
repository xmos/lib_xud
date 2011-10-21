
#include "XUD_UIFM_Functions.h"
#include "XUD_USB_Defines.h"
#include "XUD_UIFM_Defines.h"
#ifdef GLX
#include <xa1_registers.h>
#include <print.h>
#endif


#define MYID   0x0000
#define GLXID  0x0001
int write_glx_periph_word(unsigned destId, unsigned periphAddress, unsigned destRegAddr, unsigned data);
int read_glx_periph_word(unsigned destId, unsigned periphAddress, unsigned destRegAddr, unsigned &data);
void XUD_SetCrcTableAddr(unsigned addr);

/** @brief  Sets the device addres in XUD 
  * @param  addr the new address
  */ 
void XUD_SetDevAddr(unsigned addr)
{
    unsigned data;

#ifdef ARCH_L
    /* Set device address in UIFM */
#ifdef GLX
    write_glx_periph_word(GLXID, XS1_GLX_PERIPH_USB_ID, XS1_UIFM_DEVICE_ADDRESS_REG,addr);
    read_glx_periph_word(GLXID, XS1_GLX_PERIPH_USB_ID, XS1_UIFM_DEVICE_ADDRESS_REG,data);
 
    //printint(XS1_UIFM_DEVICE_ADDRESS_REG);
 
    
     //write_glx_periph_word(GLXID, XS1_GLX_PERIPH_USB_ID, XS1_UIFM_IFM_CONTROL_REG, (1<<XS1_UIFM_IFM_CONTROL_DOTOKENS) 
       //         | (1<< XS1_UIFM_IFM_CONTROL_CHECKTOKENS) 
         ///       | (1<< XS1_UIFM_IFM_CONTROL_DECODELINESTATE)
           //     | (1<< XS1_UIFM_IFM_CONTROL_SOFISTOKEN));
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
